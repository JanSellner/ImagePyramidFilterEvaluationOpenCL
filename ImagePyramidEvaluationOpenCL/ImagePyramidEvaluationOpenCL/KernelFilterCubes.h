#pragma once

#include "AKernel.h"
#include "KernelFilter.h"

class KernelFilterCubes : public KernelFilter<KernelFilterCubes>
{
public:
    KernelFilterCubes(AOpenCLInterface* const opencl, cl::Program* const program);
    virtual ~KernelFilterCubes();

    static std::string kernelSource();

    cl::Event runSingle(const cl::Image2DArray& imgSrc, SPImage2DArray& imgDst);
    cl::Event runSingleLocal(const cl::Image2DArray& imgSrc, SPImage2DArray& imgDst);
    cl::Event runSingleSeparation(const cl::Image2DArray& imgSrc, SPImage2DArray& imgDst);
    cl::Event runDouble(const cl::Image2DArray& imgSrc, SPImage2DArray& imgDst1, SPImage2DArray& imgDst2);
    cl::Event rundDoubleSeparation(const cl::Image2DArray& img, SPImage2DArray& imgDst1, SPImage2DArray& imgDst2);

    //cl::Event runDoubleCompleteKernel(const cl::Image2D& img, SPImage2D& imgDst1, SPImage2D& imgDst2, int level);
    //cl::Event runSingleCompleteKernelWithDoubleFilter(const cl::Image2D& imgSrc, SPImage2D& imgDst, int filter1, int filter2, int level);

    cl::Event runHalfsampleImage(const cl::Image2DArray& imgSrc, SPImage2DArray& imgDst);
    cl::Event runCopyInsideCube(SPImage2DArray& img);
};
