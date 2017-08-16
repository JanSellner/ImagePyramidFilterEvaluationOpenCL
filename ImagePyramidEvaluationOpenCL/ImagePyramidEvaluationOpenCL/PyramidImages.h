#pragma once

#include "APyramid.h"

class PyramidImages : public APyramid
{
public:
    explicit PyramidImages(const cv::Mat& img);
    virtual ~PyramidImages();
    
    virtual void init() override;
    virtual long long startFilterTest() override;
    virtual void readImages() override;
    virtual std::string name() override;

private:
    void createPyramid();
    void calcDerivativesSingleSeparation();
    void calcDerivativesSingleSeparationLocal();
    void calcDerivativesSingle();
    void calcDerivativesSingleLocal();
    void calcDerivativesSinglePredefined();
    void calcDerivativesSinglePredefinedLocal();
    void calcDerivativesDouble();
    void calcDerivativesDoubleLocal();
    void calcDerivativesDoubleSeparation();
    void calcDerivativesDoublePredefined();
    void calcDerivativesDoublePredefinedLocal();

private:
    cl::Program programFilter;
    KernelFilterImages kernelFilter;
    KernelFilterImages kernelFilter2;

    std::vector<SPImage2D> images;
    std::vector<SPImage2D> imagesGx;
    std::vector<SPImage2D> imagesGy;
};
