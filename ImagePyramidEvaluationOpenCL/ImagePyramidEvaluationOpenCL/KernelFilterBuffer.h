#pragma once

#include "KernelFilter.h"

class KernelFilterBuffer : public KernelFilter<KernelFilterBuffer>
{
public:
    KernelFilterBuffer(AOpenCLInterface* const opencl, cl::Program* const program);
    virtual ~KernelFilterBuffer();

    static std::string kernelSource();

    cl::Event runSingle(cl::Buffer& img, cl::Buffer& imgDst, cl::Buffer& locationLookup, int octave, const std::vector<Lookup>& lookup);
    cl::Event runSingleLocal(cl::Buffer& img, cl::Buffer& imgDst, cl::Buffer& locationLookup, int octave, const std::vector<Lookup>& lookup);
    cl::Event runSingleSeparationLocal(cl::Buffer& img, cl::Buffer& imgDst, cl::Buffer& locationLookup, int octave, const std::vector<Lookup>& lookup);

    cl::Event runHalfsampleImage(cl::Buffer& img, cl::Buffer& locationLookup, int octave, const std::vector<Lookup>& lookup);
    cl::Event runCopyInsideCube(cl::Buffer& img, cl::Buffer& locationLookup, int octave, const std::vector<Lookup>& lookup);

private:
    cl::Buffer imgTmp;
    bool bufferSet = false;
};
