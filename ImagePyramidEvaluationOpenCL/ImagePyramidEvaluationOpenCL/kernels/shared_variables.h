#ifndef SHARED_VARIABLE_H
#define SHARED_VARIABLE_H

// CLK_ADDRESS_CLAMP_TO_EDGE = aaa|abcd|ddd
constant sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;

global float lambda;
global float lambdaSquared;

struct Lookup
{
    int previousPixels;
    int imgWidth;
    int imgHeight;
};

float readValue(float* img, constant struct Lookup* lookup, int level, int x, int y)
{
    return img[lookup[level].previousPixels + lookup[level].imgWidth * y + x];
}

float readValueC(constant float* img, constant struct Lookup* lookup, int level, int x, int y)
{
    return img[lookup[level].previousPixels + lookup[level].imgWidth * y + x];
}
float readValue1D(read_only image1d_buffer_t img, constant struct Lookup* lookup, int level, int x, int y)
{
    return read_imagef(img, lookup[level].previousPixels + lookup[level].imgWidth * y + x).x;
}

//TODO: why is this overloading needed?
//float* readAddress(float* img, constant struct Lookup* lookup, int level, int x, int y)
//{
//    return &img[lookup[level].previousPixels + lookup[level].imgWidth * y + x];
//}

constant float* readAddress(constant float* img, constant struct Lookup* lookup, int level, int x, int y)
{
    return &img[lookup[level].previousPixels + lookup[level].imgWidth * y + x];
}

void writeValue(float* img, constant struct Lookup* lookup, int level, int x, int y, float value)
{
    img[lookup[level].previousPixels + lookup[level].imgWidth * y + x] = value;
}

void writeValue1D(write_only image1d_buffer_t img, constant struct Lookup* lookup, int level, int x, int y, float value)
{
    write_imagef(img, lookup[level].previousPixels + lookup[level].imgWidth * y + x, value);
}

typedef float type_single;
typedef float2 type_double;

#include "filter_images_defines.cl"

#endif
