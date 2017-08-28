#pragma once

#include "APyramid.h"
#include "KernelFilterCubes.h"

class PyramidCubes : public APyramid
{
public:
    explicit PyramidCubes(const cv::Mat& img);
    virtual ~PyramidCubes();

    virtual void init() override;
    virtual long long startFilterTest() override;
    virtual void readImages() override;
    virtual std::string name() override;

private:
    void createPyramid();
    void calcDerivativesSingleSeparation();
    void calcDerivativesSingle();
    void calcDerivativesSingleLocal();

private:
    cl::Program programFilter;
    KernelFilterCubes kernelFilter;
    KernelFilterCubes kernelFilter2;

    std::vector<SPImage2DArray> images;
    std::vector<SPImage2DArray> imagesGx;
    std::vector<SPImage2DArray> imagesGy;
};
