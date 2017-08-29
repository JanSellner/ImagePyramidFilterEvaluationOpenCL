#pragma once

#include "APyramid.h"
#include "KernelFilterBuffer.h"

class PyramidImages1D : public APyramid
{
public:
    explicit PyramidImages1D(const cv::Mat& img);
    virtual ~PyramidImages1D();

    virtual void init() override;
    virtual long long startFilterTest() override;
    virtual void readImages() override;
    virtual std::string name() override;

private:
    std::vector<cv::Mat> readImageStack(const cl::Image1DBuffer& images);
    void createPyramid();
    void calcDerivativesSingle();
    void calcDerivativesSingleLocal();
    void calcDerivativesSingleSeparationLocal();

private:
    cl::Program programFilter;
    KernelFilterBuffer<cl::Image1DBuffer> kernelFilter;
    KernelFilterBuffer<cl::Image1DBuffer> kernelFilter2;
    
    cl::Buffer bufferLocationLookup;
    std::vector<Lookup> locationLoopup;
    int totalPixels;

    cl::Buffer bufferImages;
    cl::Buffer bufferImagesGx;
    cl::Buffer bufferImagesGy;
    cl::Image1DBuffer image;
    cl::Image1DBuffer imageGx;
    cl::Image1DBuffer imageGy;
};
