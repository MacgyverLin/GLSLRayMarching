#pragma once

#include "Platform.h"
#include "Vector2.h"
#include "Matrix4.h"

#include <filesystem>
#include <iostream>

class CameraArray
{
public:
    CameraArray(const std::filesystem::path& path);
    ~CameraArray();

    void bind(size_t index, int eye_loc, int VP_loc, int st_size_loc, int st_distance_loc, float st_width, float st_distance);

    struct Camera
    {
        IVector2 size;
        Vector2 xy;
        IVector2 ij;
        int pixel_format;
        unsigned int texture;

        float focal_length;
        float sensor_width;
        Matrix4 VP;
    };

    bool light_slab;

    int findClosestCamera(const Vector2 &xy, int exclude_idx = -1);

    Vector2 xy_size;

    std::vector<Camera> cameras;
};
