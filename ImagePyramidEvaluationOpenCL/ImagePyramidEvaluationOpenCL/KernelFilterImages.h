#pragma once

#include "AKernel.h"
#include <opencv2/core.hpp>
#include "KernelFilter.h"

class KernelFilterImages : public KernelFilter<KernelFilterImages>
{
public:
    KernelFilterImages(AOpenCLInterface* const opencl, cl::Program* const program);
    virtual ~KernelFilterImages();

    static std::string kernelSource();
    
    cl::Event runSingle(const cl::Image2D& imgSrc, SPImage2D& imgDst);
    cl::Event runSingleLocal(const cl::Image2D& imgSrc, SPImage2D& imgDst);
    cl::Event runSingleLocalOnePass(const cl::Image2D& imgSrc, SPImage2D& imgDst);
    cl::Event runSingleSeparation(const cl::Image2D& imgSrc, SPImage2D& imgDst);
    cl::Event runSingleSeparationLocal(const cl::Image2D& imgSrc, SPImage2D& imgDst);
    cl::Event runSinglePredefined(const cl::Image2D& imgSrc, SPImage2D& imgDst, const std::string& name, const std::string& size);
    cl::Event runSinglePredefinedLocal(const cl::Image2D& imgSrc, SPImage2D& imgDst, const std::string& name, const std::string& size);
    cl::Event runDouble(const cl::Image2D& imgSrc, SPImage2D& imgDst1, SPImage2D& imgDst2);
    cl::Event runDoubleLocal(const cl::Image2D& imgSrc, SPImage2D& imgDst1, SPImage2D& imgDst2);
    cl::Event runDoubleSeparation(const cl::Image2D& img, SPImage2D& imgDst1, SPImage2D& imgDst2);
    cl::Event runDoublePredefined(const cl::Image2D& img, SPImage2D& imgDst1, SPImage2D& imgDst2, const std::string& name, const std::string& size);
    cl::Event runDoublePredefinedLocal(const cl::Image2D& img, SPImage2D& imgDst1, SPImage2D& imgDst2, const std::string& name, const std::string& size);

    cl::Event runHalfsampleImage(const cl::Image2D& imgSrc, SPImage2D& imgDst);

private:
    bool useUnrollFilter(int rows, int cols) const;
    bool useUnrollFilter(int rows1, int cols1, int rows2, int cols2) const;
};
