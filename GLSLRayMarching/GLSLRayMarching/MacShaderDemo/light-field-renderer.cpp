#include "light-field-renderer.h"
#include "Graphics.h"
#include <exception>
#include <iostream>
#include <fstream>

// #include <nanogui/nanogui.h>
// #include <glm/gtx/transform.hpp>
// #include <glm/gtc/matrix_transform.hpp>

// #include <nanogui/opengl.h>

#include "shaders/light-field-renderer.vert"
#include "shaders/light-field-renderer.frag"
#include "shaders/data-camera-projections.vert"
#include "shaders/screen.vert"
#include "shaders/normalize-aperture-filters.frag"

#include "shaders/autofocus/disparity.vert"
#include "shaders/autofocus/disparity.frag"
#include "shaders/autofocus/template-match.frag"
#include "shaders/autofocus/visualize-autofocus.frag"

#include "config.h"
#include "camera-array.h"
#include "util.h"

LightFieldRenderer::LightFieldRenderer(const std::shared_ptr<Config> &cfg) : 
    quad(), cfg(cfg), aperture(32),
    draw_shader(screen_vert, normalize_aperture_filters_frag),
    visualize_autofocus_shader(screen_vert, visualize_autofocus_frag),
    template_match_shader(screen_vert, template_match_frag)
{
    resize();
}

void LightFieldRenderer::draw_contents()
{
    if (!camera_array || !shader) return;

    move();

    if (continuous_autofocus || autofocus_click || visualize_autofocus)
    {
        phaseDetectionAutofocus();
        autofocus_click = false;
    }

    if (visualize_autofocus)
    {
        fbo1->bindTexture();
        visualize_autofocus_shader.use();

        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        glClear(GL_COLOR_BUFFER_BIT);

        quad.draw();

        if (save_next) saveRender();

        return;
    }

    fbo0->bind();
    aperture.bind();

    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    glEnable(GL_BLEND);
    glBlendEquation(GL_FUNC_ADD);
    glBlendFunc(GL_ONE, GL_ONE);

    shader->use();

    glUniformMatrix4fv(shader->getLocation("VP"), 1, GL_FALSE, &VP[0][0]);
    glUniform3fv(shader->getLocation("eye"), 1, &eye[0]);
    glUniform1f(shader->getLocation("focus_distance"), cfg->focus_distance);
    glUniform1f(shader->getLocation("aperture_diameter"), cfg->focal_length / cfg->f_stop);
    glUniform3fv(shader->getLocation("forward"), 1, &forward[0]);
    glUniform3fv(shader->getLocation("right"), 1, &right[0]);
    glUniform3fv(shader->getLocation("up"), 1, &up[0]);
    glUniform1f(shader->getLocation("aperture_falloff"), cfg->aperture_falloff);

    int data_eye_loc = shader->getLocation("data_eye");
    int data_VP_loc = shader->getLocation("data_VP");
    int st_size_loc = shader->getLocation("st_size");
    int st_distance_loc = shader->getLocation("st_distance");

    for (int i = 0; i < camera_array->cameras.size(); i++)
    {
        camera_array->bind(i, data_eye_loc, data_VP_loc, st_size_loc, st_distance_loc, cfg->st_width, cfg->st_distance);
        aperture.draw();
    }

    float max_weight_sum = normalize_aperture ? 0.0f : fbo0->getMaxAlpha();

    fbo0->unBind();
    fbo0->bindTexture();
    draw_shader.use();

    quad.bind();

    glUniform1f(draw_shader.getLocation("max_weight_sum"), max_weight_sum);
    glUniform1f(draw_shader.getLocation("exposure"), std::pow(2, cfg->exposure));

    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    quad.draw();

    if (save_next) saveRender();
}

Matrix4 LookAt(const Vector3& eye, const Vector3& center, const Vector3& up)
{
    Matrix4 m;

    Vector3 f = center - eye; f.Normalize();
    Vector3 s = f.Cross(up); s.Normalize();
    Vector3 u = s.Cross(f);

    Matrix4 Result;
    Result.SetIdentity();
    Result[0][0] = s.X();
    Result[1][0] = s.Y();
    Result[2][0] = s.Z();
    Result[0][1] = u.X();
    Result[1][1] = u.Y();
    Result[2][1] = u.Z();
    Result[0][2] = -f.X();
    Result[1][2] = -f.Y();
    Result[2][2] = -f.Z();
    Result[3][0] = -s.Dot(eye);
    Result[3][1] = -u.Dot(eye);
    Result[3][2] = f.Dot(eye);
    return Result;
}

void LightFieldRenderer::move()
{
    if (navigation == Navigation::ANIMATE)
    {
        animate();
    }

    if(navigation == Navigation::FREE)
    {
        forward = Vector3( std::sin(cfg->yaw),
                           -std::sin(cfg->pitch) * std::cos(cfg->yaw),
                           -std::cos(cfg->pitch) * std::cos(cfg->yaw));
    }

    double current_time = glfwGetTime();
    if (current_time > last_time && navigation != Navigation::ANIMATE)
    {
        float dx = cfg->speed * (float)(current_time - last_time);

        eye = Vector3(cfg->x, cfg->y, cfg->z);
        right = forward.Cross(Y_AXIS);
        right.Normalize();

        if (moves[FORWARD]) eye += forward * dx;
        if (moves[BACK])    eye -= forward * dx;
        if (moves[RIGHT])   eye += right * dx;
        if (moves[LEFT])    eye -= right * dx;
        if (moves[UP])      eye += Y_AXIS * dx;
        if (moves[DOWN])    eye -= Y_AXIS * dx;

        cfg->x = eye.X();
        cfg->y = eye.Y();
        cfg->z = eye.Z();
    }
    last_time = current_time;

    eye = Vector3(cfg->x, cfg->y, cfg->z);

    if (navigation != Navigation::FREE)
    {
        forward = Vector3(cfg->target_x - eye.X(), cfg->target_y - eye.Y(), cfg->target_z - eye.Z());
        forward.Normalize();
        
        cfg->yaw = std::asin(forward.X());
        cfg->pitch = std::atan2(-forward.Y(), -forward.Z());
    }

    auto view = LookAt(eye, eye + forward, Y_AXIS);
    up = Vector3(view[0][1], view[1][1], view[2][1]);
    right = Vector3(view[0][0], view[1][0], view[2][0]);

    image_distance = focus_breathing ? imageDistance(cfg->focal_length, cfg->focus_distance) : cfg->focal_length;
    auto projection = perspectiveProjection(image_distance, cfg->sensor_width, fb_size);

    VP = view * projection;
}

void LightFieldRenderer::open()
{
    try
    {
        camera_array.reset();
        camera_array = std::make_unique<CameraArray>(cfg->folder);

        if (!camera_array->light_slab)
        {
            shader = std::make_unique<Shader>(
                (std::string(light_field_renderer_vert) + std::string(perspective_projection)).c_str(),
                light_field_renderer_frag
            );
            disparity_shader = std::make_unique<Shader>(
                (std::string(disparity_vert) + std::string(perspective_projection)).c_str(),
                disparity_frag
            );
        }
        else
        {
            shader = std::make_unique<Shader>(
                (std::string(light_field_renderer_vert) + std::string(light_slab_projection)).c_str(),
                light_field_renderer_frag
            );
            disparity_shader = std::make_unique<Shader>(
                (std::string(disparity_vert) + std::string(light_slab_projection)).c_str(),
                disparity_frag
            );
        }
    }
    catch (const std::exception &ex)
    {
        std::cout << ex.what() << std::endl;
        camera_array.reset();
        shader.reset();
        disparity_shader.reset();
    }
}

bool LightFieldRenderer::mouse_drag_event(const IVector2& p, const IVector2& rel, int button, int modifiers)
{
    if (mouse_active && !click)
    {
        if (navigation == Navigation::TARGET)
        {
            cfg->x += 0.5f * cfg->speed * rel.X() / (float)fb_size.X();
            cfg->y -= 0.5f * cfg->speed * rel.Y() / (float)fb_size.X();

            forward = Vector3(cfg->target_x - cfg->x, cfg->target_y - cfg->y, cfg->target_z - cfg->z);
            forward.Normalize();
        }
        else if(navigation == Navigation::FREE)
        {
            cfg->pitch += rel.Y() / (float)fb_size.X();
            cfg->yaw += rel.X() / (float)fb_size.X();
        }
    }
    click = false;
    return true;
}

bool LightFieldRenderer::scroll_event(const IVector2& p, const Vector2& rel)
{
    cfg->focus_distance += rel.Y() * (cfg->focus_distance.getRange() / 50.0f);

    return true;
}

bool LightFieldRenderer::mouse_button_event(const IVector2 &p, int button, bool down, int modifiers)
{
    mouse_active = down && camera_array;

    if (mouse_active)
        Platform::DisableCursor();
    else
        Platform::EnableCursor();

    click = mouse_active;

    if (modifiers == GLFW_MOD_SHIFT && click)
    {
        Platform::Mouse mouse = Platform::GetMouse();
        auto px = p - IVector2(mouse.x, mouse.y);
        px.Y() = Platform::GetHeight() - px.Y();
        cfg->autofocus_x = px.X() / (float)(Platform::GetWidth());
        cfg->autofocus_y = px.Y() / (float)(Platform::GetHeight());
        autofocus_click = true;
    }

    return true;
}

void LightFieldRenderer::keyboardEvent(int key, int scancode, int action, int modifiers)
{
    bool pressed;
    switch (action)
    {
        case GLFW_PRESS: pressed = true; break;
        case GLFW_RELEASE: pressed = false; break;
        default: return;
    };

    switch (key)
    {
    case GLFW_KEY_W: moves[FORWARD] = pressed; break;
    case GLFW_KEY_S: moves[BACK] = pressed; break;
    case GLFW_KEY_A: moves[LEFT] = pressed; break;
    case GLFW_KEY_D: moves[RIGHT] = pressed; break;
    case GLFW_KEY_SPACE: moves[UP] = pressed; break;
    case GLFW_KEY_LEFT_CONTROL: moves[DOWN] = pressed; break;
    };
}

void LightFieldRenderer::resize()
{
    fb_size = IVector2(cfg->width, cfg->height);
    //set_fixed_size(IVector2(fb_size.X(), fb_size.Y()));

    //if (draw_border())
    //{
        fb_size -= IVector2(2, 2);
    //}
    //fb_size = IVector2(Vector2(fb_size) * screen()->pixel_ratio());

    fbo0 = std::make_unique<FBO>(fb_size);
    fbo1 = std::make_unique<FBO>(fb_size);
}

void LightFieldRenderer::saveNextRender(const std::string &filename)
{
    savename = std::filesystem::path(filename).replace_extension(".tga").string();
    save_next = true;
}

void LightFieldRenderer::saveRender()
{
    if (!save_next || savename.empty()) return;

    struct HeaderTGA
    {
        HeaderTGA(uint16_t width, uint16_t height)
            : width(width), height(height) {}

    private:
        uint8_t begin[12] = { 0, 0, 2 };
        uint16_t width;
        uint16_t height;
        uint8_t end[2] = { 24, 32 };
    };

    int vp[4];
    glGetIntegerv(GL_VIEWPORT, vp);

    // GL_RGBA is required for some reason
    std::vector<unsigned int> data(vp[2] * vp[3]);
    glReadPixels(vp[0], vp[1], vp[2], vp[3], GL_RGBA, GL_UNSIGNED_BYTE, data.data());

    HeaderTGA header(vp[2], vp[3]);

    std::vector<unsigned int> rearranged(vp[2] * vp[3]);
    for (int y = 0; y < vp[3]; y++)
    {
        for (int x = 0; x < vp[2]; x++)
        {
            const auto &p = data[(vp[3] - 1 - y) * vp[2] + x];
            rearranged[y * vp[2] + x] = p;
        }
    }

    std::ofstream image_file(savename, std::ios::binary);
    image_file.write(reinterpret_cast<char*>(&header), sizeof(header));
    image_file.write(reinterpret_cast<char*>(rearranged.data()), rearranged.size() * 3);
    image_file.close();

    save_next = false;
    savename = "";
}

float Mix(float x, float y, float a)
{
    return x * (1.0 - a) + y * a;
}

void LightFieldRenderer::animate()
{
    //static int current_frame = 0;
    //savename = std::string("C:\\Users\\Me\\Documents\\TNM089\\light-field-renderer\\test\\") + std::to_string(current_frame) + ".tga";
    //save_next = true;
    //constexpr float num_frames = 30*4.0f;
    //float f = current_frame / num_frames;
    //current_frame = (current_frame + 1) % (int)num_frames;

    float f = (float)glfwGetTime() / cfg->animation_duration;

    float theta = f * 360.0f * Math::Degree2Radian;
    float phi = f * std::round(cfg->animation_cycles) * 360.0f * Math::Degree2Radian;
    Vector3 r = Vector3(camera_array->xy_size.X(), camera_array->xy_size.Y(), 0.0f) / 2.0f;
    r.Z() = std::max(r.X(), r.Y()) * cfg->animation_depth;

    r *= (float)cfg->animation_scale;

    cfg->x = r.X() * std::cos(phi) * std::sin(theta);
    cfg->y = r.Y() * std::sin(phi) * std::sin(theta);
    cfg->z = r.Z() * std::cos(theta);

    cfg->target_x = Mix((1.0f - cfg->animation_sway) * cfg->x, (float)cfg->x, (1.0f - (1.0f + std::cos(theta * 2.0f)) / 2.0f));
    cfg->target_y = Mix((1.0f - cfg->animation_sway) * cfg->y, (float)cfg->y, (1.0f - (1.0f + std::cos(theta * 2.0f)) / 2.0f));

    float lim = 0.001f;
    if (cfg->z > 0.0f)
    {
        if (cfg->z < lim) 
            cfg->z = lim;
    }
    else
    {
        if (cfg->z > -lim) 
            cfg->z = -lim;
    }

    cfg->target_z = cfg->z - (r.Z() / (float)cfg->animation_scale) * 4;
}