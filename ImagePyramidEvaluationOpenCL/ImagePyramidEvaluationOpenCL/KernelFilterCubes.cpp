#include "KernelFilterCubes.h"
#include "general.h"

KernelFilterCubes::KernelFilterCubes(AOpenCLInterface* const opencl, cl::Program* const program)
    : KernelFilter(opencl, program)
{}

KernelFilterCubes::~KernelFilterCubes()
{}

std::string KernelFilterCubes::kernelSource()
{
    return getKernelSource("kernels/filter_cubes.cl");
}

cl::Event KernelFilterCubes::runSingle(const cl::Image2DArray& imgSrc, SPImage2DArray& imgDst)
{
    const size_t rows = imgSrc.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = imgSrc.getImageInfo<CL_IMAGE_WIDTH>();
    const size_t depth = imgSrc.getImageInfo<CL_IMAGE_ARRAY_SIZE>();

    ASSERT(rows > 0 && cols > 0 && depth > 0, "The image object seems to be invalid, no rows/cols/depth set");
    ASSERT(imgSrc.getImageInfo<CL_IMAGE_FORMAT>().image_channel_data_type == CL_FLOAT, "Only float type images are supported");
    ASSERT(imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_ONLY || imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_WRITE, "Can't read the input image");
    ASSERT(border == cv::BORDER_REPLICATE || border == cv::BORDER_REFLECT101, "Unsupported border type");

    imgDst = std::make_shared<cl::Image2DArray>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), depth, cols, rows, 0, 0);

    if (useUnrollFilter(kernel1.rows, kernel1.cols))
    {
        std::string filterName = "filter_single_" + std::to_string(kernel1.rows) + "x" + std::to_string(kernel1.cols);

        cl::Kernel kernel(*program, filterName.c_str());
        kernel.setArg(0, imgSrc);
        kernel.setArg(1, *imgDst);
        kernel.setArg(2, bufferKernel1);
        kernel.setArg(3, border);

        cl::Event eventFilter;
        const cl::NDRange global(cols, rows, depth);
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
        const cl::NDRange global(cols, rows, depth);
        queue->enqueueNDRangeKernel(kernel, cl::NullRange, global, local, &events, &eventFilter);

        // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
        events.clear();

        return eventFilter;
    }
}

cl::Event KernelFilterCubes::runSingleLocal(const cl::Image2DArray& imgSrc, SPImage2DArray& imgDst)
{
    const size_t rows = imgSrc.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = imgSrc.getImageInfo<CL_IMAGE_WIDTH>();
    const size_t depth = imgSrc.getImageInfo<CL_IMAGE_ARRAY_SIZE>();

    ASSERT(rows > 0 && cols > 0 && depth > 0, "The image object seems to be invalid, no rows/cols/depth set");
    ASSERT(imgSrc.getImageInfo<CL_IMAGE_FORMAT>().image_channel_data_type == CL_FLOAT, "Only float type images are supported");
    ASSERT(imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_ONLY || imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_WRITE, "Can't read the input image");
    ASSERT(border == cv::BORDER_REPLICATE || border == cv::BORDER_REFLECT101, "Unsupported border type");

    imgDst = std::make_shared<cl::Image2DArray>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), depth, cols, rows, 0, 0);

    if (useUnrollFilter(kernel1.rows, kernel1.cols))
    {
        std::string filterName = "filter_single_local_" + std::to_string(kernel1.rows) + "x" + std::to_string(kernel1.cols);

        cl::Kernel kernel(*program, filterName.c_str());
        kernel.setArg(0, imgSrc);
        kernel.setArg(1, *imgDst);
        kernel.setArg(2, bufferKernel1);
        kernel.setArg(3, border);

        cl::Event eventFilter;
        const cl::NDRange global(cols, rows, depth);
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
        const cl::NDRange global(cols, rows, depth);
        queue->enqueueNDRangeKernel(kernel, cl::NullRange, global, local, &events, &eventFilter);

        // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
        events.clear();

        return eventFilter;
    }
}

cl::Event KernelFilterCubes::runSingleSeparation(const cl::Image2DArray& imgSrc, SPImage2DArray& imgDst)
{
    const size_t rows = imgSrc.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = imgSrc.getImageInfo<CL_IMAGE_WIDTH>();
    const size_t depth = imgSrc.getImageInfo<CL_IMAGE_ARRAY_SIZE>();

    ASSERT(rows > 0 && cols > 0 && depth > 0, "The image object seems to be invalid, no rows/cols/depth set");
    ASSERT(imgSrc.getImageInfo<CL_IMAGE_FORMAT>().image_channel_data_type == CL_FLOAT, "Only float type images are supported");
    ASSERT(imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_ONLY || imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_WRITE, "Can't read the input image");
    ASSERT(border == cv::BORDER_REPLICATE || border == cv::BORDER_REFLECT101, "Unsupported border type");

    cl::Image2DArray imgTmp(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), depth, cols, rows, 0, 0);
    imgDst = std::make_shared<cl::Image2DArray>(*context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), depth, cols, rows, 0, 0);

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
        const cl::NDRange global(cols, rows, depth);
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
        const cl::NDRange global(cols, rows, depth);
        queue->enqueueNDRangeKernel(kernelX, cl::NullRange, global, local, &events);
        queue->enqueueNDRangeKernel(kernelY, cl::NullRange, global, local, nullptr, &eventFilter);

        // Clear for next call. From the OpenCL API side this is no problem since the event list can be freed after the enqueue function returns
        events.clear();

        return eventFilter;
    }
}

cl::Event KernelFilterCubes::runHalfsampleImage(const cl::Image2DArray& imgSrc, SPImage2DArray& imgDst)
{
    const size_t rows = imgSrc.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = imgSrc.getImageInfo<CL_IMAGE_WIDTH>();
    const size_t depth = imgSrc.getImageInfo<CL_IMAGE_ARRAY_SIZE>();

    ASSERT(rows > 0 && cols > 0, "The image object seems to be invalid, no rows/cols set");
    ASSERT(imgSrc.getImageInfo<CL_IMAGE_FORMAT>().image_channel_data_type == CL_FLOAT, "Only float type images are supported");
    ASSERT(imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_ONLY || imgSrc.getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_WRITE, "Can't read the input image");

    imgDst = std::make_shared<cl::Image2DArray>(*context, CL_MEM_READ_ONLY, cl::ImageFormat(CL_R, CL_FLOAT), depth, cols / 2, rows / 2, 0, 0);

    cl::Kernel kernelConductivty(*program, "fed_resize");
    kernelConductivty.setArg(0, imgSrc);
    kernelConductivty.setArg(1, *imgDst);

    cl::Event event;
    const cl::NDRange global(cols / 2, rows / 2);
    queue->enqueueNDRangeKernel(kernelConductivty, cl::NullRange, global, cl::NullRange, &events, &event);

    events.clear();

    return event;
}

cl::Event KernelFilterCubes::runCopyInsideCube(SPImage2DArray& img)
{
    const size_t rows = img->getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = img->getImageInfo<CL_IMAGE_WIDTH>();
    const size_t depth = img->getImageInfo<CL_IMAGE_ARRAY_SIZE>();

    ASSERT(rows > 0 && cols > 0, "The image object seems to be invalid, no rows/cols set");
    ASSERT(img->getImageInfo<CL_IMAGE_FORMAT>().image_channel_data_type == CL_FLOAT, "Only float type images are supported");
    ASSERT(img->getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_ONLY || img->getInfo<CL_MEM_FLAGS>() == CL_MEM_READ_WRITE, "Can't read the input image");

    cl::Kernel kernelConductivty(*program, "copy_inside_cube");
    kernelConductivty.setArg(0, *img);

    cl::Event event;
    const cl::NDRange offset(0, 0, 1);
    const cl::NDRange global(cols, rows, depth - 1);
    queue->enqueueNDRangeKernel(kernelConductivty, offset, global, cl::NullRange, &events, &event);

    events.clear();

    return event;
}
