#include "PyramidImages.h"
#include <opencv2/imgproc.hpp>

PyramidImages::PyramidImages(const cv::Mat& img)
    : APyramid(img),
      kernelFilter(&opencl, &programFilter),
      kernelFilter2(&opencl, &programFilter)
{}

PyramidImages::~PyramidImages()
{}

void PyramidImages::init()
{
    try
    {
        opencl.selectDevice();
        opencl.init();

        programFilter = cl::Program(opencl.getContext(), AKernel<KernelFilterImages>::kernelSource());

#ifdef DEBUG_INTEL
        programFilter.build((opencl.getBuildOptions() + " -Werror -g -s kernels/filter_images.cl").c_str());
#else
        programFilter.build(opencl.getBuildOptions().c_str());
#endif

        createPyramid();
        opencl.getQueue().finish();
    }
    catch (const cl::BuildError& buildError)
    {
        std::cout << buildError.what() << " (" << buildError.err() << "), build info:" << std::endl;
        for (const auto& b : buildError.getBuildLog())
        {
            std::cout << b.second << std::endl;
        }
    }
    catch (const cl::Error& error)
    {
        std::cout << error.what() << " (" << error.err() << ")" << std::endl;
    }
}

long long PyramidImages::startFilterTest()
{
    long long diff = 0;

    std::chrono::steady_clock::time_point begin = std::chrono::steady_clock::now();

    switch (settings.method)
    {
        case SINGLE_SEPARATION:
            calcDerivativesSingleSeparation();
            break;
        case SINGLE:
            calcDerivativesSingle();
            break;
        case DOUBLE:
            calcDerivativesDouble();
            break;
        case DOUBLE_LOCAL:
            calcDerivativesDoubleLocal();
            break;
        case DOUBLE_SEPARATION:
            calcDerivativesDoubleSeparation();
            break;
        case SINGLE_LOCAL:
            calcDerivativesSingleLocal();
            break;
        case SINGLE_SEPARATION_LOCAL:
            calcDerivativesSingleSeparationLocal();
            break;
        case SINGLE_PREDEFINED:
            calcDerivativesSinglePredefined();
            break;
        case DOUBLE_PREDEFINED:
            calcDerivativesDoublePredefined();
            break;
        case SINGLE_PREDEFINED_LOCAL:
            calcDerivativesSinglePredefinedLocal();
            break;
        case DOUBLE_PREDEFINED_LOCAL:
            calcDerivativesDoublePredefinedLocal();
            break;
        default:
            break;
    }

    opencl.getQueue().finish();

    std::chrono::steady_clock::time_point end = std::chrono::steady_clock::now();
    diff = std::chrono::duration_cast<std::chrono::milliseconds>(end - begin).count();

    return diff;
}

void PyramidImages::readImages()
{
    std::vector<cv::Mat> img(pyramidSize);
    std::vector<cv::Mat> imgGx(pyramidSize);
    std::vector<cv::Mat> imgGy(pyramidSize);

    for (size_t i = 0; i < img.size(); ++i)
    {
        img[i] = opencl.copyImageFromDevice(*images[i]);
        imgGx[i] = opencl.copyImageFromDevice(*imagesGx[i]);
        imgGy[i] = opencl.copyImageFromDevice(*imagesGy[i]);
    }

    cv::Mat testGx;
    cv::sepFilter2D(img[0], testGx, CV_32FC1, Gx2, Gx1);

    cv::Mat testGy;
    cv::filter2D(img[0], testGy, CV_32FC1, Gy);
}

std::string PyramidImages::name()
{
    return "Image";
}

void PyramidImages::createPyramid()
{
    images.resize(pyramidSize);
    imagesGx.resize(pyramidSize);
    imagesGy.resize(pyramidSize);

    // Allocate global memory on the device
    images[0] = std::make_shared<cl::Image2D>(opencl.getContext(), CL_MEM_READ_ONLY, cl::ImageFormat(CL_R, CL_FLOAT), img.cols, img.rows);

    // Copy the data to the GPU
    cl::Event lastEvent;
    std::array<size_t, 3> origin = { 0, 0, 0 };
    std::array<size_t, 3> imgSize = { static_cast<size_t>(img.cols), static_cast<size_t>(img.rows), 1 };
    opencl.getQueue().enqueueWriteImage(*images[0], CL_NON_BLOCKING, origin, imgSize, img.cols * sizeof(float), 0, img.data, nullptr, &lastEvent);

    for (size_t i = 1; i < images.size(); ++i)
    {
        if (i % 4 == 0)
        {
            lastEvent = kernelFilter.runHalfsampleImage(*images[i - 1], images[i]);
        }
        else
        {
            lastEvent = opencl.copyImageOnDevice(*images[i - 1], images[i], lastEvent);
            kernelFilter.addEvent(lastEvent);
        }
    }
}

void PyramidImages::calcDerivativesSingleSeparation()
{
    kernelFilter.setKernelSeparation1(Gx1, Gx2);
    kernelFilter2.setKernelSeparation1(Gy1, Gy2);

    kernelFilter.setBorder(cv::BORDER_DEFAULT);
    kernelFilter2.setBorder(cv::BORDER_DEFAULT);

    for (size_t i = 0; i < images.size(); ++i)
    {
        kernelFilter.runSingleSeparation(*images[i], imagesGx[i]);
        kernelFilter2.runSingleSeparation(*images[i], imagesGy[i]);
    }
}

void PyramidImages::calcDerivativesSingleSeparationLocal()
{
    kernelFilter.setKernelSeparation1(Gx1, Gx2);
    kernelFilter2.setKernelSeparation1(Gy1, Gy2);

    kernelFilter.setBorder(cv::BORDER_DEFAULT);
    kernelFilter2.setBorder(cv::BORDER_DEFAULT);

    for (size_t i = 0; i < images.size(); ++i)
    {
        kernelFilter.runSingleSeparationLocal(*images[i], imagesGx[i]);
        kernelFilter2.runSingleSeparationLocal(*images[i], imagesGy[i]);
    }
}

void PyramidImages::calcDerivativesSingle()
{
    kernelFilter.setKernel1(Gx);
    kernelFilter2.setKernel1(Gy);

    kernelFilter.setBorder(cv::BORDER_DEFAULT);
    kernelFilter2.setBorder(cv::BORDER_DEFAULT);

    for (size_t i = 0; i < images.size(); ++i)
    {
        kernelFilter.runSingle(*images[i], imagesGx[i]);
        kernelFilter2.runSingle(*images[i], imagesGy[i]);
    }
}

void PyramidImages::calcDerivativesSingleLocal()
{
    kernelFilter.setKernel1(Gx);
    kernelFilter2.setKernel1(Gy);

    kernelFilter.setBorder(cv::BORDER_DEFAULT);
    kernelFilter2.setBorder(cv::BORDER_DEFAULT);

    for (size_t i = 0; i < images.size(); ++i)
    {
        kernelFilter.runSingleLocal(*images[i], imagesGx[i]);
        kernelFilter2.runSingleLocal(*images[i], imagesGy[i]);
    }
}

void PyramidImages::calcDerivativesSinglePredefined()
{
    kernelFilter.setBorder(cv::BORDER_DEFAULT);
    kernelFilter2.setBorder(cv::BORDER_DEFAULT);

    for (size_t i = 0; i < images.size(); ++i)
    {
        kernelFilter.runSinglePredefined(*images[i], imagesGx[i], "Gx", std::to_string(Gx.rows) + "x" + std::to_string(Gx.cols));
        kernelFilter2.runSinglePredefined(*images[i], imagesGy[i], "Gy", std::to_string(Gy.rows) + "x" + std::to_string(Gy.cols));
    }
}

void PyramidImages::calcDerivativesDoubleLocal()
{
    kernelFilter.setKernel1(Gx);
    kernelFilter.setKernel2(Gy);

    kernelFilter.setBorder(cv::BORDER_DEFAULT);

    for (size_t i = 0; i < images.size(); ++i)
    {
        kernelFilter.runDoubleLocal(*images[i], imagesGx[i], imagesGy[i]);
    }
}

void PyramidImages::calcDerivativesSinglePredefinedLocal()
{
    kernelFilter.setBorder(cv::BORDER_DEFAULT);
    kernelFilter2.setBorder(cv::BORDER_DEFAULT);

    for (size_t i = 0; i < images.size(); ++i)
    {
        kernelFilter.runSinglePredefinedLocal(*images[i], imagesGx[i], "Gx", std::to_string(Gx.rows) + "x" + std::to_string(Gx.cols));
        kernelFilter2.runSinglePredefinedLocal(*images[i], imagesGy[i], "Gy", std::to_string(Gy.rows) + "x" + std::to_string(Gy.cols));
    }
}

void PyramidImages::calcDerivativesDouble()
{
    kernelFilter.setKernel1(Gx);
    kernelFilter.setKernel2(Gy);

    kernelFilter.setBorder(cv::BORDER_DEFAULT);

    for (size_t i = 0; i < images.size(); ++i)
    {
        kernelFilter.runDouble(*images[i], imagesGx[i], imagesGy[i]);
    }
}

void PyramidImages::calcDerivativesDoubleSeparation()
{
    kernelFilter.setKernelSeparation1(Gx1, Gx2);
    kernelFilter.setKernelSeparation2(Gy1, Gy2);

    kernelFilter.setBorder(cv::BORDER_DEFAULT);

    for (size_t i = 0; i < images.size(); ++i)
    {
        kernelFilter.runDoubleSeparation(*images[i], imagesGx[i], imagesGy[i]);
    }
}

void PyramidImages::calcDerivativesDoublePredefined()
{
    kernelFilter.setBorder(cv::BORDER_DEFAULT);

    for (size_t i = 0; i < images.size(); ++i)
    {
        kernelFilter.runDoublePredefined(*images[i], imagesGx[i], imagesGy[i], "GxGy", std::to_string(Gx.rows) + "x" + std::to_string(Gx.cols));
    }
}

void PyramidImages::calcDerivativesDoublePredefinedLocal()
{
    kernelFilter.setBorder(cv::BORDER_DEFAULT);

    for (size_t i = 0; i < images.size(); ++i)
    {
        kernelFilter.runDoublePredefinedLocal(*images[i], imagesGx[i], imagesGy[i], "GxGy", std::to_string(Gx.rows) + "x" + std::to_string(Gx.cols));
    }
}
