#pragma once

#include "Math.h"

inline std::ostream& operator<<(std::ostream& out, const Vector3& v)
{
    return out << std::string("( " + std::to_string(v.X()) + ", " + std::to_string(v.Y()) + ", " + std::to_string(v.Z()) + " )");
}

// Perspective projection without near and far clipping
inline Matrix4 perspectiveProjection(float image_distance, float sensor_width, IVector2 size)
{   
    Matrix4 P = Matrix4::Zero;
    P[0][0] = (2.0f * image_distance) / sensor_width;
    P[1][1] = (2.0f * image_distance * size.X()) / (sensor_width * size.Y());
    P[2][3] = -1.0f;
    return  P;
}

// From thin-lens equation
inline float imageDistance(float focal_length, float focus_distance)
{
    return (focus_distance * focal_length) / (focus_distance - focal_length);
}
