#pragma once

#include "opencl_common.h"
#include <opencv2/core.hpp>

struct Lookup
{
    int previousPixels;
    int imgWidth;
    int imgHeight;
};

class AOpenCLInterface
{
public:
    AOpenCLInterface()
    {}
    virtual ~AOpenCLInterface()
    {}

    virtual cv::Mat copyImageFromDevice(const cl::Image2D& img) const = 0;
    virtual cv::Mat copyImageFromDevice(const cl::Image2DArray& img, size_t idx) const = 0;

    virtual cl::Device& getDevice() = 0;
    virtual cl::Context& getContext() = 0;
    virtual cl::CommandQueue& getQueue() = 0;
    virtual cl::CommandQueue& getQueue2() = 0;
};
