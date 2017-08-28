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

    cl::Event runHalfsampleImage(const cl::Image2DArray& imgSrc, SPImage2DArray& imgDst);
    cl::Event runCopyInsideCube(SPImage2DArray& img);
};
