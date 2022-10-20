#include "light-field-renderer.h"
#include "config.h"
#include "camera-array.h"
#include "fbo.h"
#include "util.h"
#include "Graphics.h"

Vector3 closestPointBetweenRays(const Vector3&p0, const Vector3&d0, const Vector3 &p1, const Vector3&d1);

void LightFieldRenderer::phaseDetectionAutofocus()
{
    int v0 = (int)std::round(cfg->template_size);
    const IVector2 template_size(v0, v0);
    int v1 = (int)std::round(cfg->template_size * cfg->search_scale);
    const IVector2 search_size(v1, v1);

    IVector2 af_pos(cfg->autofocus_x * fb_size.X(), cfg->autofocus_y * fb_size.Y());

    IVector2::Clamp(af_pos, search_size / 2 + 1, fb_size - (search_size / 2 + IVector2(1, 1)));

    cfg->autofocus_x = af_pos.X() / (float)fb_size.X();
    cfg->autofocus_y = af_pos.Y() / (float)fb_size.Y();

    IVector2 cameras;
    cameras.X() = camera_array->findClosestCamera(pixelToCameraPlane(Vector2(fb_size.X(), fb_size.Y()) * 0.4f));
    cameras.Y() = camera_array->findClosestCamera(pixelToCameraPlane(Vector2(fb_size.X(), fb_size.Y()) * 0.6f), cameras.X());

    IVector2 template_min(af_pos - template_size / 2);
    IVector2 template_max(af_pos + template_size / 2);
    
    IVector2 search_min(af_pos - search_size / 2);
    IVector2 search_max(af_pos + search_size / 2);

    fbo1->bind();

    quad.bind();

    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    glEnable(GL_BLEND);
    glBlendEquation(GL_FUNC_ADD);
    glBlendFunc(GL_ONE, GL_ONE);

    // Discard fragments outside of search region
    if(!visualize_autofocus)
        glScissor(search_min.X(), search_min.Y(), search_size.X(), search_size.Y());

    disparity_shader->use();

    // Size of visible part of focal plane
    Vector2 focal_plane_size = (Vector2(fb_size.X(), fb_size.Y()) / (float)fb_size.X()) * (cfg->sensor_width / image_distance) * (float)cfg->focus_distance;

    glUniformMatrix4fv(disparity_shader->getLocation("VP"), 1, GL_FALSE, &VP[0][0]);
    glUniform3fv(disparity_shader->getLocation("eye"), 1, &eye[0]);
    glUniform1f(disparity_shader->getLocation("focus_distance"), cfg->focus_distance);
    glUniform2fv(disparity_shader->getLocation("size"), 1, &focal_plane_size[0]);
    glUniform3fv(disparity_shader->getLocation("forward"), 1, &forward[0]);
    glUniform3fv(disparity_shader->getLocation("right"), 1, &right[0]);
    glUniform3fv(disparity_shader->getLocation("up"), 1, &up[0]);

    int data_eye_loc = disparity_shader->getLocation("data_eye");
    int data_VP_loc = disparity_shader->getLocation("data_VP");
    int st_size_loc = disparity_shader->getLocation("st_size");
    int st_distance_loc = disparity_shader->getLocation("st_distance");

    for (int i = 0; i < 2; i++)
    {
        camera_array->bind(cameras[i], data_eye_loc, data_VP_loc, st_size_loc, st_distance_loc, cfg->st_width, cfg->st_distance);
        glUniform1i(disparity_shader->getLocation("channel"), i);
        quad.draw();
    }
    
    fbo1->unBind();

    if (visualize_autofocus)
    {
        visualize_autofocus_shader.use();

        glUniform2iv(visualize_autofocus_shader.getLocation("size"), 1, &fb_size[0]);
        glUniform2iv(visualize_autofocus_shader.getLocation("template_min"), 1, &template_min[0]);
        glUniform2iv(visualize_autofocus_shader.getLocation("template_max"), 1, &template_max[0]);
        glUniform2iv(visualize_autofocus_shader.getLocation("search_min"), 1, &search_min[0]);
        glUniform2iv(visualize_autofocus_shader.getLocation("search_max"), 1, &search_max[0]);

        if(!(continuous_autofocus || autofocus_click)) return;
    }

    fbo0->bind();
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    fbo1->bindTexture();

    // Discard fragments outside of search region
    glScissor(search_min.X(), search_min.Y(), search_size.X(), search_size.Y());

    template_match_shader.use();

    glUniform2iv(template_match_shader.getLocation("size"), 1, &fb_size[0]);
    glUniform2iv(template_match_shader.getLocation("template_min"), 1, &template_min[0]);
    glUniform2iv(template_match_shader.getLocation("template_max"), 1, &template_max[0]);

    quad.draw();

    if (sqdiff_data.size() != search_size.X() * search_size.Y())
    {
        sqdiff_data.resize(search_size.X() * search_size.Y());
    }
    glReadPixels(search_min.X(), search_min.Y(), search_size.X(), search_size.Y(), GL_RED, GL_FLOAT, sqdiff_data.data());
    fbo0->unBind();

    Vector2 best;
    float min_diff = std::numeric_limits<float>::max();
    for (int x = 0; x < search_size.X(); x++)
    {
        for (int y = 0; y < search_size.Y(); y++)
        {
            float diff = sqdiff_data[x + y * search_size.Y()];
            if (diff < min_diff)
            {
                min_diff = diff;
                best = Vector2(x, y);
            }
        }
    }

    best += Vector2(template_size.X(), template_size.Y()) * 0.5f;

    Vector2 pixel_phase_difference = (Vector2(search_size.X(), search_size.Y()) * 0.5f) - best;

    // Pixels projected to focal plane
    Vector3 f0 = pixelToFocalPlane(Vector2(af_pos.X(), af_pos.Y()));
    Vector3 f1 = pixelToFocalPlane(Vector2(af_pos.X(), af_pos.Y()) + pixel_phase_difference);

    // Camera positions
    Vector2& vv0 = camera_array->cameras[cameras.X()].xy;
    Vector2& vv1 = camera_array->cameras[cameras.X()].xy;
    Vector3 c0 = Vector3(vv0.X(), vv0.Y(), 0.0f);
    Vector3 c1 = Vector3(vv1.X(), vv1.Y(), 0.0f);

    // Directions from cameras to points on focal plane
    Vector3 d0 = f0 - c0; d0.Normalize();
    Vector3 d1 = f1 - c1; d1.Normalize();

    // Point on new focal plane
    Vector3 nf = closestPointBetweenRays(c0, d0, c1, d1);

    cfg->focus_distance = (nf - eye).Dot(forward);
}

Vector3 LightFieldRenderer::pixelDirection(const Vector2 &px)
{
    float x = (float)cfg->sensor_width * ((px.X() - (fb_size.X() * 0.5f)) / fb_size.X());
    float y = (float)cfg->sensor_width * ((px.Y() - (fb_size.Y() * 0.5f)) / fb_size.Y());

    Vector3 v = right* x + up * y + forward * image_distance;
    v.Normalize();
    return v;
}

Vector3 LightFieldRenderer::pixelToFocalPlane(const Vector2 &px)
{
    Vector3 direction = pixelDirection(px);
    return eye + direction * ((float)cfg->focus_distance / direction.Dot(forward));
}

Vector2 LightFieldRenderer::pixelToCameraPlane(const Vector2 &px)
{
    Vector3 direction = pixelDirection(px);
    return Vector2(eye.X(), eye.Y()) + Vector2(direction.X(), direction.Y()) * (-eye.Z() / direction.Z());
}

Vector3 closestPointBetweenRays(const Vector3&p0, const Vector3&d0, const Vector3&p1, const Vector3&d1)
{
    float a = d0.Dot(d0);
    float b = d0.Dot(d1);
    float e = d1.Dot(d1);

    float d = a * e - b * b;

    // Lines are parallel
    if (d == 0.0f) return 0.5f * (p0 + p1);;

    Vector3 r = p0 - p1;
    float c = d0.Dot(r);
    float f = d1.Dot(r);

    float s = (b*f - c * e) / d;
    float t = (a*f - c * b) / d;

    return 0.5f * ((p0 + d0 * s) + (p1 + d1 * t));
};