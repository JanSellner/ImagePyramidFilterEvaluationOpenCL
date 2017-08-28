#pragma once

#include "AKernel.h"
#include "general.h"
#include "settings.h"

template<class Derived>
class KernelFilter : public AKernel<Derived>
{
public:
    KernelFilter(AOpenCLInterface* const opencl, cl::Program* const program)
        : AKernel<Derived>(opencl, program)
    {}

    virtual ~KernelFilter()
    {}

    void setKernel1(const cv::Mat& filter1)
    {
        this->kernel1 = filter1;
        bufferKernel1 = cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(float) * this->kernel1.rows * this->kernel1.cols);

        cl::Event eventKernel;
        queue->enqueueWriteBuffer(bufferKernel1, CL_NON_BLOCKING, 0, sizeof(float) * this->kernel1.rows * this->kernel1.cols, this->kernel1.data, nullptr, &eventKernel);
        events.push_back(eventKernel);
    }

    void setKernel2(const cv::Mat& filter2)
    {
        this->kernel2 = filter2;
        bufferKernel2 = cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(float) * this->kernel2.rows * this->kernel2.cols);

        cl::Event eventKernel;
        queue->enqueueWriteBuffer(bufferKernel2, CL_NON_BLOCKING, 0, sizeof(float) * this->kernel2.rows * this->kernel2.cols, this->kernel2.data, nullptr, &eventKernel);
        events.push_back(eventKernel);
    }

    void setKernelSeparation1(const cv::Mat& filterKernelA, const cv::Mat& filterKernelB)
    {
        checkSeparationFilter(filterKernelA, filterKernelB);

        this->kernelSeparation1A = filterKernelA;
        this->kernelSeparation1B = filterKernelB;

        const int size = this->kernelSeparation1A.rows * this->kernelSeparation1A.cols;

        bufferKernelSeparation1A = cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(float) * size);
        bufferKernelSeparation1B = cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(float) * size);

        cl::Event eventKernelA;
        cl::Event eventKernelB;
        queue->enqueueWriteBuffer(bufferKernelSeparation1A, CL_NON_BLOCKING, 0, sizeof(float) * size, this->kernelSeparation1A.data, nullptr, &eventKernelA);
        queue->enqueueWriteBuffer(bufferKernelSeparation1B, CL_NON_BLOCKING, 0, sizeof(float) * size, this->kernelSeparation1B.data, nullptr, &eventKernelB);
        events.push_back(eventKernelA);
        events.push_back(eventKernelB);
    }

    void setKernelSeparation2(const cv::Mat& filterKerne2A, const cv::Mat& filterKerne2B)
    {
        checkSeparationFilter(filterKerne2A, filterKerne2B);

        this->kernelSeparation2A = filterKerne2A;
        this->kernelSeparation2B = filterKerne2B;

        const int size = this->kernelSeparation2A.rows * this->kernelSeparation2A.cols;

        bufferKernelSeparation2A = cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(float) * size);
        bufferKernelSeparation2B = cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(float) * size);

        cl::Event eventKernelA;
        cl::Event eventKernelB;
        queue->enqueueWriteBuffer(bufferKernelSeparation2A, CL_NON_BLOCKING, 0, sizeof(float) * size, this->kernelSeparation2A.data, nullptr, &eventKernelA);
        queue->enqueueWriteBuffer(bufferKernelSeparation2B, CL_NON_BLOCKING, 0, sizeof(float) * size, this->kernelSeparation2B.data, nullptr, &eventKernelB);
        events.push_back(eventKernelA);
        events.push_back(eventKernelB);
    }

    int getBorder() const
    {
        return border;
    }

    void setBorder(const int border)
    {
        this->border = border;
    }

    void setBufferKernelCompleteX1X2Y1Y2(const cv::Mat& kernelDoubleComplete)
    {
        ASSERT(kernelDoubleComplete.isContinuous(), "The kernel must be stored continuously in memory");
        this->kernelDoubleComplete = kernelDoubleComplete;

        const int size = this->kernelDoubleComplete.rows * this->kernelDoubleComplete.cols;
        bufferKernelCompleteX1X2Y1Y2 = cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(float) * size);

        cl::Event eventKernel;
        queue->enqueueWriteBuffer(bufferKernelCompleteX1X2Y1Y2, CL_NON_BLOCKING, 0, sizeof(float) *size, this->kernelDoubleComplete.data, nullptr, &eventKernel);
        events.push_back(eventKernel);
    }

    std::vector<Lookup>& getLookupKernelDoubleComplete()
    {
        return lookupKernelDoubleComplete;
    }

    void setLookupKernelDoubleComplete(const std::vector<Lookup>& lookupKernelDoubleComplete)
    {
        this->lookupKernelDoubleComplete = lookupKernelDoubleComplete;

        bufferLookupKernelDouble = cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(Lookup) * this->lookupKernelDoubleComplete.size());

        cl::Event eventBuffer;
        queue->enqueueWriteBuffer(bufferLookupKernelDouble, CL_NON_BLOCKING, 0, sizeof(Lookup) *  this->lookupKernelDoubleComplete.size(), this->lookupKernelDoubleComplete.data(), nullptr, &eventBuffer);
        events.push_back(eventBuffer);
    }

protected:
    bool useUnrollFilter(int rows, int cols) const
    {
        return unroll && (
            rows == 3 && cols == 3 ||
            rows == 5 && cols == 5 ||
            rows == 7 && cols == 7 ||
            rows == 9 && cols == 9);
    }

    bool useUnrollFilter(int rows1, int cols1, int rows2, int cols2) const
    {
        return unroll && (
            (rows1 == 1 && cols1 == 3 && rows2 == 3 && cols2 == 1) ||
            (rows1 == 3 && cols1 == 1 && rows2 == 1 && cols2 == 3) ||
            (rows1 == 1 && cols1 == 5 && rows2 == 5 && cols2 == 1) ||
            (rows1 == 5 && cols1 == 1 && rows2 == 1 && cols2 == 5) ||
            (rows1 == 1 && cols1 == 7 && rows2 == 7 && cols2 == 1) ||
            (rows1 == 7 && cols1 == 1 && rows2 == 1 && cols2 == 7) ||
            (rows1 == 1 && cols1 == 9 && rows2 == 9 && cols2 == 1) ||
            (rows1 == 9 && cols1 == 1 && rows2 == 1 && cols2 == 9));
    }

private:
    void checkKernelColumnVector(const cv::Mat& filterKernelX) const
    {
        ASSERT(!filterKernelX.empty(), "Kernel must be non-empty");
        ASSERT(filterKernelX.rows > 1 && filterKernelX.cols == 1, "filterKernelX must be a column vector");
        ASSERT(filterKernelX.type() == CV_32FC1, "Only single-chanel float type filters are supported");
        ASSERT(filterKernelX.rows % 2 == 1, "The filter size must be odd");
    }

    void checkKernelRowVector(const cv::Mat& filterKernelY) const
    {
        ASSERT(!filterKernelY.empty(), "Kernel must be non-empty");
        ASSERT(filterKernelY.rows == 1 && filterKernelY.cols > 1, "filterKernelY must be a row vector");
        ASSERT(filterKernelY.type() == CV_32FC1, "Only single-chanel float type filters are supported");
        ASSERT(filterKernelY.cols % 2 == 1, "The filter size must be odd");
    }

    void checkSeparationFilter(const cv::Mat& filterA, const cv::Mat& filterB)
    {
        ASSERT(!filterA.empty(), "Kernel must be non-empty");
        ASSERT(!filterB.empty(), "Kernel must be non-empty");
        ASSERT(filterA.rows * filterA.cols == filterB.rows * filterB.cols, "Both filter must have the same number of elements");
        ASSERT(filterA.type() == CV_32FC1, "Only single-chanel float type filters are supported");
        ASSERT(filterB.type() == CV_32FC1, "Only single-chanel float type filters are supported");
        ASSERT(filterA.cols % 2 == 1 || filterB.cols % 2 == 1, "At least one filter must be a column filter");
        ASSERT(filterA.rows % 2 == 1 || filterB.rows % 2 == 1, "At least one filter must be a row filter");
    }

protected:
    cl::Buffer bufferKernel1;
    cv::Mat kernel1;
    cl::Buffer bufferKernel2;
    cv::Mat kernel2;

    cl::Buffer bufferKernelSeparation1A;
    cl::Buffer bufferKernelSeparation1B;
    cv::Mat kernelSeparation1A;
    cv::Mat kernelSeparation1B;
    cl::Buffer bufferKernelSeparation2A;
    cl::Buffer bufferKernelSeparation2B;
    cv::Mat kernelSeparation2A;
    cv::Mat kernelSeparation2B;

    cl::Buffer bufferKernelCompleteX1X2Y1Y2;
    cv::Mat kernelDoubleComplete;
    cl::Buffer bufferLookupKernelDouble;
    std::vector<Lookup> lookupKernelDoubleComplete;

    int border = cv::BORDER_REPLICATE;
};
