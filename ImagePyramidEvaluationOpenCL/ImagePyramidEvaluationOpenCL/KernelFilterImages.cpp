#include "KernelFilterImages.h"
#include "general.h"
#include <numeric>

KernelFilterImages::KernelFilterImages(AOpenCLInterface* const opencl, cl::Program* const program)
    : KernelFilter(opencl, program)
{}

KernelFilterImages::~KernelFilterImages()
{}

std::string KernelFilterImages::kernelSource()
{
    return getKernelSource("kernels/filter_images.cl");
}

cl::Event KernelFilterImages::runSingle(const cl::Image2D& imgSrc, SPImage2D& imgDst)
{
    const size_t rows = imgSrc.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = imgSrc.getImageInfo<CL_IMAGE_WIDTH>();

    ASSERT(rows > 0 && cols > 0, "The image object seems to be invalid, no rows/cols set");
    ASSERT(imgSrc.getImageInfo<CL_IMAGE_FORMAT>().image_channel_data_type == CL_FLOAT, "Only float type images are supported");
    ASSERT(imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_ONLY || imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_WRITE, "Can't read the input image");
    ASSERT(border == cv::BORDER_REPLICATE || border == cv::BORDER_REFLECT101, "Unsupported border type");

    imgDst = std::make_shared<cl::Image2D>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);

    if (useUnrollFilter(kernel1.rows, kernel1.cols))
    {
        std::string filterName = "filter_single_" + std::to_string(kernel1.rows) + "x" + std::to_string(kernel1.cols);

        cl::Kernel kernel(*program, filterName.c_str());
        kernel.setArg(0, imgSrc);
        kernel.setArg(1, *imgDst);
        kernel.setArg(2, bufferKernel1);
        kernel.setArg(3, border);

        cl::Event eventFilter;
        const cl::NDRange global(cols, rows);
        queue->enqueueNDRangeKernel(kernel, cl::NullRange, global, local, &events, &eventFilter);

        // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
        events.clear();

        return eventFilter;
    }
    else
    {
        cl::Kernel kernel(*program, "filter_single");
        kernel.setArg(0, imgSrc);
        kernel.setArg(1, *imgDst);
        kernel.setArg(2, bufferKernel1);
        kernel.setArg(3, kernel1.rows / 2);
        kernel.setArg(4, kernel1.cols);
        kernel.setArg(5, kernel1.cols / 2);
        kernel.setArg(6, border);

        cl::Event eventFilter;
        const cl::NDRange global(cols, rows);
        queue->enqueueNDRangeKernel(kernel, cl::NullRange, global, local, &events, &eventFilter);

        // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
        events.clear();

        return eventFilter;
    }
}

cl::Event KernelFilterImages::runSingleLocal(const cl::Image2D& imgSrc, SPImage2D& imgDst)
{
    const size_t rows = imgSrc.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = imgSrc.getImageInfo<CL_IMAGE_WIDTH>();

    ASSERT(rows > 0 && cols > 0, "The image object seems to be invalid, no rows/cols set");
    ASSERT(imgSrc.getImageInfo<CL_IMAGE_FORMAT>().image_channel_data_type == CL_FLOAT, "Only float type images are supported");
    ASSERT(imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_ONLY || imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_WRITE, "Can't read the input image");
    ASSERT(border == cv::BORDER_REPLICATE || border == cv::BORDER_REFLECT101, "Unsupported border type");

    imgDst = std::make_shared<cl::Image2D>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);

    if (useUnrollFilter(kernel1.rows, kernel1.cols))
    {
        std::string filterName = "filter_single_local_" + std::to_string(kernel1.rows) + "x" + std::to_string(kernel1.cols);

        cl::Kernel kernel(*program, filterName.c_str());
        kernel.setArg(0, imgSrc);
        kernel.setArg(1, *imgDst);
        kernel.setArg(2, bufferKernel1);
        kernel.setArg(3, border);

        cl::Event eventFilter;
        const cl::NDRange global(cols, rows);
        queue->enqueueNDRangeKernel(kernel, cl::NullRange, global, local, &events, &eventFilter);

        // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
        events.clear();

        return eventFilter;
    }
    else
    {
        cl::Kernel kernel(*program, "filter_single_local");
        kernel.setArg(0, imgSrc);
        kernel.setArg(1, *imgDst);
        kernel.setArg(2, bufferKernel1);
        kernel.setArg(3, kernel1.rows / 2);
        kernel.setArg(4, kernel1.cols);
        kernel.setArg(5, kernel1.cols / 2);
        kernel.setArg(6, border);

        cl::Event eventFilter;
        const cl::NDRange global(cols, rows);
        queue->enqueueNDRangeKernel(kernel, cl::NullRange, global, local, &events, &eventFilter);

        // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
        events.clear();

        return eventFilter;
    }
}

cl::Event KernelFilterImages::runSingleLocalOnePass(const cl::Image2D& imgSrc, SPImage2D& imgDst)
{
    const size_t rows = imgSrc.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = imgSrc.getImageInfo<CL_IMAGE_WIDTH>();

    ASSERT(rows > 0 && cols > 0, "The image object seems to be invalid, no rows/cols set");
    ASSERT(imgSrc.getImageInfo<CL_IMAGE_FORMAT>().image_channel_data_type == CL_FLOAT, "Only float type images are supported");
    ASSERT(imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_ONLY || imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_WRITE, "Can't read the input image");
    ASSERT(border == cv::BORDER_REPLICATE || border == cv::BORDER_REFLECT101, "Unsupported border type");

    imgDst = std::make_shared<cl::Image2D>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);

    if (useUnrollFilter(kernelSeparation1A.rows, kernelSeparation1A.cols, kernelSeparation1B.rows, kernelSeparation1B.cols))
    {
        std::string filterName = "filter_single_local_onePass_" + std::to_string(kernelSeparation1A.cols) + "x" + std::to_string(kernelSeparation1B.rows);

        cl::Kernel kernel(*program, filterName.c_str());
        kernel.setArg(0, imgSrc);
        kernel.setArg(1, *imgDst);
        kernel.setArg(2, bufferKernelSeparation1A);
        kernel.setArg(3, bufferKernelSeparation1B);
        kernel.setArg(4, border);

        cl::Event eventFilter;
        const cl::NDRange global(cols, rows);
        queue->enqueueNDRangeKernel(kernel, cl::NullRange, global, local, &events);

        // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
        events.clear();

        return eventFilter;
    }
    else
    {
        cl::Kernel kernel(*program, "filter_single_local_onePass");
        kernel.setArg(0, imgSrc);
        kernel.setArg(1, *imgDst);
        kernel.setArg(2, bufferKernelSeparation1A);
        kernel.setArg(3, bufferKernelSeparation1B);
        kernel.setArg(4, kernelSeparation1A.cols / 2);
        kernel.setArg(5, kernelSeparation1A.cols);
        kernel.setArg(6, kernelSeparation1A.cols / 2);
        kernel.setArg(7, border);

        cl::Event eventFilter;
        const cl::NDRange global(cols, rows);
        queue->enqueueNDRangeKernel(kernel, cl::NullRange, global, local, &events);

        // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
        events.clear();

        return eventFilter;
    }
}

cl::Event KernelFilterImages::runSingleSeparation(const cl::Image2D& imgSrc, SPImage2D& imgDst)
{
    const size_t rows = imgSrc.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = imgSrc.getImageInfo<CL_IMAGE_WIDTH>();

    ASSERT(rows > 0 && cols > 0, "The image object seems to be invalid, no rows/cols set");
    ASSERT(imgSrc.getImageInfo<CL_IMAGE_FORMAT>().image_channel_data_type == CL_FLOAT, "Only float type images are supported");
    ASSERT(imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_ONLY || imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_WRITE, "Can't read the input image");
    ASSERT(border == cv::BORDER_REPLICATE || border == cv::BORDER_REFLECT101, "Unsupported border type");

    cl::Image2D imgTmp(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);
    imgDst = std::make_shared<cl::Image2D>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);

    if (useUnrollFilter(kernelSeparation1A.rows, kernelSeparation1A.cols, kernelSeparation1B.rows, kernelSeparation1B.cols))
    {
        std::string filterNameX = "filter_single_" + std::to_string(kernelSeparation1A.rows) + "x" + std::to_string(kernelSeparation1A.cols);
        std::string filterNameY = "filter_single_" + std::to_string(kernelSeparation1B.rows) + "x" + std::to_string(kernelSeparation1B.cols);

        cl::Kernel kernelX(*program, filterNameX.c_str());
        kernelX.setArg(0, imgSrc);
        kernelX.setArg(1, imgTmp);
        kernelX.setArg(2, bufferKernelSeparation1A);
        kernelX.setArg(3, border);

        cl::Kernel kernelY(*program, filterNameY.c_str());
        kernelY.setArg(0, imgTmp);
        kernelY.setArg(1, *imgDst);
        kernelY.setArg(2, bufferKernelSeparation1B);
        kernelY.setArg(3, border);

        cl::Event eventFilter;
        const cl::NDRange global(cols, rows);
        queue->enqueueNDRangeKernel(kernelX, cl::NullRange, global, local, &events);
        queue->enqueueNDRangeKernel(kernelY, cl::NullRange, global, local, nullptr, &eventFilter);

        // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
        events.clear();

        return eventFilter;
    }
    else
    {
        cl::Kernel kernelX(*program, "filter_single");
        kernelX.setArg(0, imgSrc);
        kernelX.setArg(1, imgTmp);
        kernelX.setArg(2, bufferKernelSeparation1A);
        kernelX.setArg(3, kernelSeparation1A.rows / 2);
        kernelX.setArg(4, kernelSeparation1A.cols);
        kernelX.setArg(5, kernelSeparation1A.cols / 2);
        kernelX.setArg(6, border);

        cl::Kernel kernelY(*program, "filter_single");
        kernelY.setArg(0, imgTmp);
        kernelY.setArg(1, *imgDst);
        kernelY.setArg(2, bufferKernelSeparation1B);
        kernelY.setArg(3, kernelSeparation1B.rows / 2);
        kernelY.setArg(4, kernelSeparation1B.cols);
        kernelY.setArg(5, kernelSeparation1B.cols / 2);
        kernelY.setArg(6, border);

        cl::Event eventFilter;
        const cl::NDRange global(cols, rows);
        queue->enqueueNDRangeKernel(kernelX, cl::NullRange, global, local, &events);
        queue->enqueueNDRangeKernel(kernelY, cl::NullRange, global, local, nullptr, &eventFilter);

        // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
        events.clear();

        return eventFilter;
    }
}

cl::Event KernelFilterImages::runSingleSeparationLocal(const cl::Image2D& imgSrc, SPImage2D& imgDst)
{
    const size_t rows = imgSrc.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = imgSrc.getImageInfo<CL_IMAGE_WIDTH>();

    ASSERT(rows > 0 && cols > 0, "The image object seems to be invalid, no rows/cols set");
    ASSERT(imgSrc.getImageInfo<CL_IMAGE_FORMAT>().image_channel_data_type == CL_FLOAT, "Only float type images are supported");
    ASSERT(imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_ONLY || imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_WRITE, "Can't read the input image");
    ASSERT(border == cv::BORDER_REPLICATE || border == cv::BORDER_REFLECT101, "Unsupported border type");

    cl::Image2D imgTmp(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);
    imgDst = std::make_shared<cl::Image2D>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);

    if (useUnrollFilter(kernelSeparation1A.rows, kernelSeparation1A.cols, kernelSeparation1B.rows, kernelSeparation1B.cols))
    {
        std::string filterNameX = "filter_single_local_" + std::to_string(kernelSeparation1A.rows) + "x" + std::to_string(kernelSeparation1A.cols);
        std::string filterNameY = "filter_single_local_" + std::to_string(kernelSeparation1B.rows) + "x" + std::to_string(kernelSeparation1B.cols);

        cl::Kernel kernelX(*program, filterNameX.c_str());
        kernelX.setArg(0, imgSrc);
        kernelX.setArg(1, imgTmp);
        kernelX.setArg(2, bufferKernelSeparation1A);
        kernelX.setArg(3, border);

        cl::Kernel kernelY(*program, filterNameY.c_str());
        kernelY.setArg(0, imgTmp);
        kernelY.setArg(1, *imgDst);
        kernelY.setArg(2, bufferKernelSeparation1B);
        kernelY.setArg(3, border);

        cl::Event eventFilter;
        const cl::NDRange global(cols, rows);
        queue->enqueueNDRangeKernel(kernelX, cl::NullRange, global, local, &events);
        queue->enqueueNDRangeKernel(kernelY, cl::NullRange, global, local, nullptr, &eventFilter);

        // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
        events.clear();

        return eventFilter;
    }
    else
    {
        cl::Kernel kernelX(*program, "filter_single_local");
        kernelX.setArg(0, imgSrc);
        kernelX.setArg(1, imgTmp);
        kernelX.setArg(2, bufferKernelSeparation1A);
        kernelX.setArg(3, kernelSeparation1A.rows / 2);
        kernelX.setArg(4, kernelSeparation1A.cols);
        kernelX.setArg(5, kernelSeparation1A.cols / 2);
        kernelX.setArg(6, border);

        cl::Kernel kernelY(*program, "filter_single_local");
        kernelY.setArg(0, imgTmp);
        kernelY.setArg(1, *imgDst);
        kernelY.setArg(2, bufferKernelSeparation1B);
        kernelY.setArg(3, kernelSeparation1B.rows / 2);
        kernelY.setArg(4, kernelSeparation1B.cols);
        kernelY.setArg(5, kernelSeparation1B.cols / 2);
        kernelY.setArg(6, border);

        cl::Event eventFilter;
        const cl::NDRange global(cols, rows);
        queue->enqueueNDRangeKernel(kernelX, cl::NullRange, global, local, &events);
        queue->enqueueNDRangeKernel(kernelY, cl::NullRange, global, local, nullptr, &eventFilter);

        // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
        events.clear();

        return eventFilter;
    }
}

cl::Event KernelFilterImages::runSinglePredefined(const cl::Image2D& imgSrc, SPImage2D& imgDst, const std::string& name, const std::string& size)
{
    const size_t rows = imgSrc.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = imgSrc.getImageInfo<CL_IMAGE_WIDTH>();

    ASSERT(rows > 0 && cols > 0, "The image object seems to be invalid, no rows/cols set");
    ASSERT(imgSrc.getImageInfo<CL_IMAGE_FORMAT>().image_channel_data_type == CL_FLOAT, "Only float type images are supported");
    ASSERT(imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_ONLY || imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_WRITE, "Can't read the input image");
    ASSERT(border == cv::BORDER_REPLICATE || border == cv::BORDER_REFLECT101, "Unsupported border type");

    imgDst = std::make_shared<cl::Image2D>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);

    std::string filterName = "filter_single_" + name + "_" + size;

    cl::Kernel kernel(*program, filterName.c_str());
    kernel.setArg(0, imgSrc);
    kernel.setArg(1, *imgDst);
    kernel.setArg(2, border);

    cl::Event eventFilter;
    const cl::NDRange global(cols, rows);
    queue->enqueueNDRangeKernel(kernel, cl::NullRange, global, local, &events, &eventFilter);

    // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
    events.clear();

    return eventFilter;
}

cl::Event KernelFilterImages::runSinglePredefinedLocal(const cl::Image2D& imgSrc, SPImage2D& imgDst, const std::string& name, const std::string& size)
{
    const size_t rows = imgSrc.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = imgSrc.getImageInfo<CL_IMAGE_WIDTH>();

    ASSERT(rows > 0 && cols > 0, "The image object seems to be invalid, no rows/cols set");
    ASSERT(imgSrc.getImageInfo<CL_IMAGE_FORMAT>().image_channel_data_type == CL_FLOAT, "Only float type images are supported");
    ASSERT(imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_ONLY || imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_WRITE, "Can't read the input image");
    ASSERT(border == cv::BORDER_REPLICATE || border == cv::BORDER_REFLECT101, "Unsupported border type");

    imgDst = std::make_shared<cl::Image2D>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);

    std::string filterName = "filter_single_local_" + name + "_" + size;

    cl::Kernel kernel(*program, filterName.c_str());
    kernel.setArg(0, imgSrc);
    kernel.setArg(1, *imgDst);
    kernel.setArg(2, border);

    cl::Event eventFilter;
    const cl::NDRange global(cols, rows);
    queue->enqueueNDRangeKernel(kernel, cl::NullRange, global, local, &events, &eventFilter);

    // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
    events.clear();

    return eventFilter;
}

cl::Event KernelFilterImages::runDouble(const cl::Image2D& imgSrc, SPImage2D& imgDst1, SPImage2D& imgDst2)
{
    const size_t rows = imgSrc.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = imgSrc.getImageInfo<CL_IMAGE_WIDTH>();

    ASSERT(rows > 0 && cols > 0, "The image object seems to be invalid, no rows/cols set");
    ASSERT(imgSrc.getImageInfo<CL_IMAGE_FORMAT>().image_channel_data_type == CL_FLOAT, "Only float type images are supported");
    ASSERT(imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_ONLY || imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_WRITE, "Can't read the input image");
    ASSERT(border == cv::BORDER_REPLICATE || border == cv::BORDER_REFLECT101, "Unsupported border type");
    ASSERT(kernel1.size == kernel2.size, "Both filter must have the same size");

    imgDst1 = std::make_shared<cl::Image2D>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);
    imgDst2 = std::make_shared<cl::Image2D>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);

    if (useUnrollFilter(kernel1.rows, kernel1.cols))
    {
        std::string filterName = "filter_double_" + std::to_string(kernel1.rows) + "x" + std::to_string(kernel1.cols);

        cl::Kernel kernel(*program, filterName.c_str());
        kernel.setArg(0, imgSrc);
        kernel.setArg(1, *imgDst1);
        kernel.setArg(2, *imgDst2);
        kernel.setArg(3, bufferKernel1);
        kernel.setArg(4, bufferKernel2);
        kernel.setArg(5, border);

        cl::Event eventFilter;
        const cl::NDRange global(cols, rows);
        queue->enqueueNDRangeKernel(kernel, cl::NullRange, global, local, &events, &eventFilter);

        // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
        events.clear();

        return eventFilter;
    }
    else
    {
        cl::Kernel kernel(*program, "filter_double");
        kernel.setArg(0, imgSrc);
        kernel.setArg(1, *imgDst1);
        kernel.setArg(2, *imgDst2);
        kernel.setArg(3, bufferKernel1);
        kernel.setArg(4, bufferKernel2);
        kernel.setArg(5, kernel1.rows / 2);
        kernel.setArg(6, kernel1.cols);
        kernel.setArg(7, kernel1.cols / 2);
        kernel.setArg(8, border);

        cl::Event eventFilter;
        const cl::NDRange global(cols, rows);
        queue->enqueueNDRangeKernel(kernel, cl::NullRange, global, local, &events, &eventFilter);

        // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
        events.clear();

        return eventFilter;
    }
}

cl::Event KernelFilterImages::runDoubleLocal(const cl::Image2D& imgSrc, SPImage2D& imgDst1, SPImage2D& imgDst2)
{
    const size_t rows = imgSrc.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = imgSrc.getImageInfo<CL_IMAGE_WIDTH>();

    ASSERT(rows > 0 && cols > 0, "The image object seems to be invalid, no rows/cols set");
    ASSERT(imgSrc.getImageInfo<CL_IMAGE_FORMAT>().image_channel_data_type == CL_FLOAT, "Only float type images are supported");
    ASSERT(imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_ONLY || imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_WRITE, "Can't read the input image");
    ASSERT(border == cv::BORDER_REPLICATE || border == cv::BORDER_REFLECT101, "Unsupported border type");
    ASSERT(kernel1.size == kernel2.size, "Both filter must have the same size");

    imgDst1 = std::make_shared<cl::Image2D>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);
    imgDst2 = std::make_shared<cl::Image2D>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);

    if (useUnrollFilter(kernel1.rows, kernel1.cols))
    {
        std::string filterName = "filter_double_local_" + std::to_string(kernel1.rows) + "x" + std::to_string(kernel1.cols);

        cl::Kernel kernel(*program, filterName.c_str());
        kernel.setArg(0, imgSrc);
        kernel.setArg(1, *imgDst1);
        kernel.setArg(2, *imgDst2);
        kernel.setArg(3, bufferKernel1);
        kernel.setArg(4, bufferKernel2);
        kernel.setArg(5, border);

        cl::Event eventFilter;
        const cl::NDRange global(cols, rows);
        queue->enqueueNDRangeKernel(kernel, cl::NullRange, global, local, &events, &eventFilter);

        // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
        events.clear();

        return eventFilter;
    }
    else
    {
        cl::Kernel kernel(*program, "filter_double_local");
        kernel.setArg(0, imgSrc);
        kernel.setArg(1, *imgDst1);
        kernel.setArg(2, *imgDst2);
        kernel.setArg(3, bufferKernel1);
        kernel.setArg(4, bufferKernel2);
        kernel.setArg(5, kernel1.rows / 2);
        kernel.setArg(6, kernel1.cols);
        kernel.setArg(7, kernel1.cols / 2);
        kernel.setArg(8, border);

        cl::Event eventFilter;
        const cl::NDRange global(cols, rows);
        queue->enqueueNDRangeKernel(kernel, cl::NullRange, global, local, &events, &eventFilter);

        // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
        events.clear();

        return eventFilter;
    }
}

cl::Event KernelFilterImages::runDoubleSeparation(const cl::Image2D& img, SPImage2D& imgDst1, SPImage2D& imgDst2)
{
    ASSERT(kernelSeparation1A.size == kernelSeparation2A.size, "Both A filters must be of same size");
    ASSERT(kernelSeparation1B.size == kernelSeparation2B.size, "Both B filters must be of same size");

    const size_t rows = img.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = img.getImageInfo<CL_IMAGE_WIDTH>();

    ASSERT(rows > 0 && cols > 0, "The image object seems to be invalid, no rows/cols set");
    ASSERT(img.getImageInfo<CL_IMAGE_FORMAT>().image_channel_data_type == CL_FLOAT, "Only float type images are supported");
    ASSERT(img.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_ONLY || img.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_WRITE, "Can't read the input image");
    ASSERT(border == cv::BORDER_REPLICATE || border == cv::BORDER_REFLECT101, "Unsupported border type");

    cl::Image2D imgTmp1(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);
    cl::Image2D imgTmp2(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);

    imgDst1 = std::make_shared<cl::Image2D>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);
    imgDst2 = std::make_shared<cl::Image2D>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);

    if (useUnrollFilter(kernelSeparation1A.rows, kernelSeparation1A.cols, kernelSeparation1B.rows, kernelSeparation1B.cols))
    {
        std::string filterName1 = "filter_double_" + std::to_string(kernelSeparation1A.rows) + "x" + std::to_string(kernelSeparation1A.cols);
        std::string filterName2 = "filter_single_" + std::to_string(kernelSeparation1B.rows) + "x" + std::to_string(kernelSeparation1B.cols);
        std::string filterName3 = "filter_single_" + std::to_string(kernelSeparation2B.rows) + "x" + std::to_string(kernelSeparation2B.cols);

        cl::Kernel kernelStep1(*program, filterName1.c_str());
        kernelStep1.setArg(0, img);
        kernelStep1.setArg(1, imgTmp1);
        kernelStep1.setArg(2, imgTmp2);
        kernelStep1.setArg(3, bufferKernelSeparation1A);
        kernelStep1.setArg(4, bufferKernelSeparation2A);
        kernelStep1.setArg(5, border);

        cl::Kernel kernelStep2(*program, filterName2.c_str());
        kernelStep2.setArg(0, imgTmp1);
        kernelStep2.setArg(1, *imgDst1);
        kernelStep2.setArg(2, bufferKernelSeparation1B);
        kernelStep2.setArg(3, border);

        cl::Kernel kernelStep3(*program, filterName3.c_str());
        kernelStep3.setArg(0, imgTmp2);
        kernelStep3.setArg(1, *imgDst2);
        kernelStep3.setArg(2, bufferKernelSeparation2B);
        kernelStep3.setArg(3, border);

        cl::Event eventKernel;
        const cl::NDRange global(cols, rows);
        queue->enqueueNDRangeKernel(kernelStep1, cl::NullRange, global, local, &events);
        queue->enqueueNDRangeKernel(kernelStep2, cl::NullRange, global, local);
        queue->enqueueNDRangeKernel(kernelStep3, cl::NullRange, global, local, nullptr, &eventKernel);

        events.clear();

        return eventKernel;
    }
    else
    {
        cl::Kernel kernelStep1(*program, "filter_double");
        kernelStep1.setArg(0, img);
        kernelStep1.setArg(1, imgTmp1);
        kernelStep1.setArg(2, imgTmp2);
        kernelStep1.setArg(3, bufferKernelSeparation1A);
        kernelStep1.setArg(4, bufferKernelSeparation2A);
        kernelStep1.setArg(5, kernelSeparation1A.rows / 2);
        kernelStep1.setArg(6, kernelSeparation1A.cols);
        kernelStep1.setArg(7, kernelSeparation1A.cols / 2);
        kernelStep1.setArg(8, border);

        cl::Kernel kernelStep2(*program, "filter_single");
        kernelStep2.setArg(0, imgTmp1);
        kernelStep2.setArg(1, *imgDst1);
        kernelStep2.setArg(2, bufferKernelSeparation1B);
        kernelStep2.setArg(3, kernelSeparation1B.rows / 2);
        kernelStep2.setArg(4, kernelSeparation1B.cols);
        kernelStep2.setArg(5, kernelSeparation1B.cols / 2);
        kernelStep2.setArg(6, border);

        cl::Kernel kernelStep3(*program, "filter_single");
        kernelStep3.setArg(0, imgTmp2);
        kernelStep3.setArg(1, *imgDst2);
        kernelStep3.setArg(2, bufferKernelSeparation2B);
        kernelStep3.setArg(3, kernelSeparation2B.rows / 2);
        kernelStep3.setArg(4, kernelSeparation2B.cols);
        kernelStep3.setArg(5, kernelSeparation2B.cols / 2);
        kernelStep3.setArg(6, border);

        cl::Event eventKernel;
        const cl::NDRange global(cols, rows);
        queue->enqueueNDRangeKernel(kernelStep1, cl::NullRange, global, local, &events);
        queue->enqueueNDRangeKernel(kernelStep2, cl::NullRange, global, local);
        queue->enqueueNDRangeKernel(kernelStep3, cl::NullRange, global, local, nullptr, &eventKernel);

        events.clear();

        return eventKernel;
    }
}

cl::Event KernelFilterImages::runDoublePredefined(const cl::Image2D& img, SPImage2D& imgDst1, SPImage2D& imgDst2, const std::string& name, const std::string& size)
{
    const size_t rows = img.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = img.getImageInfo<CL_IMAGE_WIDTH>();

    ASSERT(rows > 0 && cols > 0, "The image object seems to be invalid, no rows/cols set");
    ASSERT(img.getImageInfo<CL_IMAGE_FORMAT>().image_channel_data_type == CL_FLOAT, "Only float type images are supported");
    ASSERT(img.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_ONLY || img.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_WRITE, "Can't read the input image");
    ASSERT(border == cv::BORDER_REPLICATE || border == cv::BORDER_REFLECT101, "Unsupported border type");
    ASSERT(kernel1.size == kernel2.size, "Both filter must have the same size");

    imgDst1 = std::make_shared<cl::Image2D>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);
    imgDst2 = std::make_shared<cl::Image2D>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);

    std::string filterName = "filter_double_" + name + "_" + size;

    cl::Kernel kernel(*program, filterName.c_str());
    kernel.setArg(0, img);
    kernel.setArg(1, *imgDst1);
    kernel.setArg(2, *imgDst2);
    kernel.setArg(3, border);

    cl::Event eventFilter;
    const cl::NDRange global(cols, rows);
    queue->enqueueNDRangeKernel(kernel, cl::NullRange, global, local, &events, &eventFilter);

    // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
    events.clear();

    return eventFilter;
}

cl::Event KernelFilterImages::runDoublePredefinedLocal(const cl::Image2D& img, SPImage2D& imgDst1, SPImage2D& imgDst2, const std::string& name, const std::string& size)
{
    const size_t rows = img.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = img.getImageInfo<CL_IMAGE_WIDTH>();

    ASSERT(rows > 0 && cols > 0, "The image object seems to be invalid, no rows/cols set");
    ASSERT(img.getImageInfo<CL_IMAGE_FORMAT>().image_channel_data_type == CL_FLOAT, "Only float type images are supported");
    ASSERT(img.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_ONLY || img.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_WRITE, "Can't read the input image");
    ASSERT(border == cv::BORDER_REPLICATE || border == cv::BORDER_REFLECT101, "Unsupported border type");
    ASSERT(kernel1.size == kernel2.size, "Both filter must have the same size");

    imgDst1 = std::make_shared<cl::Image2D>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);
    imgDst2 = std::make_shared<cl::Image2D>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);

    std::string filterName = "filter_double_local_" + name + "_" + size;

    cl::Kernel kernel(*program, filterName.c_str());
    kernel.setArg(0, img);
    kernel.setArg(1, *imgDst1);
    kernel.setArg(2, *imgDst2);
    kernel.setArg(3, border);

    cl::Event eventFilter;
    const cl::NDRange global(cols, rows);
    queue->enqueueNDRangeKernel(kernel, cl::NullRange, global, local, &events, &eventFilter);

    // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
    events.clear();

    return eventFilter;
}

cl::Event KernelFilterImages::runHalfsampleImage(const cl::Image2D& imgSrc, SPImage2D& imgDst)
{
    const size_t rows = imgSrc.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = imgSrc.getImageInfo<CL_IMAGE_WIDTH>();

    ASSERT(rows > 0 && cols > 0, "The image object seems to be invalid, no rows/cols set");
    ASSERT(imgSrc.getImageInfo<CL_IMAGE_FORMAT>().image_channel_data_type == CL_FLOAT, "Only float type images are supported");
    ASSERT(imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_ONLY || imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_WRITE, "Can't read the input image");

    imgDst = std::make_shared<cl::Image2D>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols / 2, rows / 2);

    cl::Kernel kernelConductivty(*program, "fed_resize");
    kernelConductivty.setArg(0, imgSrc);
    kernelConductivty.setArg(1, *imgDst);

    cl::Event event;
    const cl::NDRange global(cols / 2, rows / 2);
    queue->enqueueNDRangeKernel(kernelConductivty, cl::NullRange, global, cl::NullRange, &events, &event);

    events.clear();

    return event;
}
