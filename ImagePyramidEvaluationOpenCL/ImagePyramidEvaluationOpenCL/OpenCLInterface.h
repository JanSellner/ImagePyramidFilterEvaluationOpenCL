#pragma once

#include <opencv2/core.hpp>
#include "opencl_common.h"
#include "KernelFilterImages.h"

class AOpenCLInterface;

class OpenCLInterface : public AOpenCLInterface
{
public:
    OpenCLInterface();
    virtual ~OpenCLInterface();

    void selectDevice();
    void init();

    cl::Event createImageOnDevice(const cv::Mat& img, cl::Image2D& imgOpencl) const;
    cl::Event copyImageOnDevice(const cl::Image2D& imgSrc, SPImage2D& imgDst, const cl::Event& event);
    virtual cv::Mat copyImageFromDevice(const cl::Image2D& img) const override;
    virtual cv::Mat copyImageFromDevice(const cl::Image2DArray& img, size_t idx) const override;

    virtual cl::Device& getDevice() override;
    virtual cl::Context& getContext() override;
    virtual cl::CommandQueue& getQueue() override;
    virtual cl::CommandQueue& getQueue2() override;

    std::string& getBuildOptions();
    std::string& getBuildOptionsDebug();

private:
    cl::Device device;
    cl::Context context;
    cl::CommandQueue queue;
    cl::CommandQueue queue2;

    std::string buildOptions = "-cl-std=CL2.0 -I kernels";
    std::string buildOptionsDebug = "-cl-std=CL2.0 -I kernels -Werror -g -s kernels/filter_images.cl";
};
