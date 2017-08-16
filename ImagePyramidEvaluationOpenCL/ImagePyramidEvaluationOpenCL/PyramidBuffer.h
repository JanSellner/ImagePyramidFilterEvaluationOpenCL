#pragma once

#include "APyramid.h"
#include "KernelFilterBuffer.h"

class PyramidBuffer : public APyramid
{
public:
    explicit PyramidBuffer(const cv::Mat& img);
    virtual ~PyramidBuffer();

    virtual void init() override;
    virtual long long startFilterTest() override;
    virtual void readImages() override;
    virtual std::string name() override;

private:
    std::vector<cv::Mat> readImageStack(const cl::Buffer& images);
    void createPyramid();
    void calcDerivativesSingle();
    void calcDerivativesSingleLocal();
    void calcDerivativesSingleSeparationLocal();

private:
    cl::Program programFilter;
    KernelFilterBuffer kernelFilter;
    KernelFilterBuffer kernelFilter2;
    
    cl::Buffer bufferLocationLookup;
    std::vector<Lookup> locationLoopup;
    int totalPixels;

    cl::Buffer images;
    cl::Buffer imagesGx;
    cl::Buffer imagesGy;
};
