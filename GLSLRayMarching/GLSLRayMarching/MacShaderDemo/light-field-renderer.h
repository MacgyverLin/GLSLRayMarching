#pragma once

#include "Platform.h"
#include <filesystem>

//#include <nanogui/canvas.h>
//#include <glm/glm.hpp>

#include "shader.h"
#include "quad.h"
#include "n-sided-polygon.h"
#include "Vector2.h"
#include "Vector3.h"
#include "Vector4.h"
#include "Matrix4.h"
#include "FBO.h"
#include "camera-array.h"
#include "Config.h"

class LightFieldRenderer
{
public:
    LightFieldRenderer(const std::shared_ptr<Config> &cfg);

    void draw_contents();

    void move();
    void open();
    void resize();
    void saveNextRender(const std::string& filename);

    bool mouse_drag_event(const IVector2& p, const IVector2& rel, int button, int modifiers);
    bool scroll_event(const IVector2& p, const Vector2& rel);
    bool mouse_button_event(const IVector2& p, int button, bool down, int modifiers);
    void keyboardEvent(int key, int scancode, int action, int modifiers);

    Vector3 forward, right, up, eye;
    Matrix4 VP;
    const Vector3 Y_AXIS = Vector3(0.0f, 1.0f, 0.0f);
    IVector2 fb_size;
    float image_distance;

    double last_time = std::numeric_limits<double>::max();

    enum Move
    {
        FORWARD,
        BACK,
        LEFT,
        RIGHT,
        DOWN,
        UP,
        NUM
    };

    std::vector<bool> moves = std::vector<bool>(Move::NUM, false);

    enum Navigation
    {
        FREE,
        TARGET,
        ANIMATE
    };

    Navigation navigation = Navigation::FREE;

    bool mouse_active = false;
    bool normalize_aperture = true;
    bool continuous_autofocus = false;
    bool autofocus_click = false;
    bool focus_breathing = false;

    bool visualize_autofocus = false;

    // Used to prevent large relative movement the first click
    bool click = false;

private:
    // The following functions are implemented in phase-detect-autofocus.cpp
    void phaseDetectionAutofocus();
    Vector3 pixelDirection(const Vector2 &px);
    Vector3 pixelToFocalPlane(const Vector2 &px);
    Vector2 pixelToCameraPlane(const Vector2 &px);
    std::vector<float> sqdiff_data;

    std::shared_ptr<Config> cfg;
    std::unique_ptr<CameraArray> camera_array;
    std::unique_ptr<Shader> shader;
    std::unique_ptr<Shader> disparity_shader;
    Shader draw_shader;
    Shader visualize_autofocus_shader;
    Shader template_match_shader;
    Quad quad;
    NSidedPolygon aperture;
    std::unique_ptr<FBO> fbo0;
    std::unique_ptr<FBO> fbo1;

    void saveRender();
    bool save_next = false;
    std::string savename = "";

    void animate();
};
