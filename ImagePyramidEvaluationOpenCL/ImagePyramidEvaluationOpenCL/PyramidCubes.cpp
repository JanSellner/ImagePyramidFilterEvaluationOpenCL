#include "PyramidCubes.h"
#include <opencv2/imgproc.hpp>

PyramidCubes::PyramidCubes(const cv::Mat& img)
    : APyramid(img),
      kernelFilter(&opencl, &programFilter),
      kernelFilter2(&opencl, &programFilter)
{}

PyramidCubes::~PyramidCubes()
{}

void PyramidCubes::init()
{
    try
    {
        opencl.selectDevice();

        opencl.init();

        programFilter = cl::Program(opencl.getContext(), AKernel<KernelFilterCubes>::kernelSource());
        programFilter.build(opencl.getBuildOptions().c_str());
        //programFilter.build((opencl.getBuildOptions() + " -Werror -g -s kernels/filter.cl").c_str());

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

long long PyramidCubes::startFilterTest()
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
        case SINGLE_LOCAL:
            calcDerivativesSingleLocal();
            break;
        default:
            break;
    }

    opencl.getQueue().finish();

    std::chrono::steady_clock::time_point end = std::chrono::steady_clock::now();
    diff = std::chrono::duration_cast<std::chrono::milliseconds>(end - begin).count();

    return diff;
}

void PyramidCubes::readImages()
{
    std::vector<cv::Mat> img(pyramidSize);
    std::vector<cv::Mat> imgGx(pyramidSize);
    std::vector<cv::Mat> imgGy(pyramidSize);

    int i = 0;
    for (size_t o = 0; o < numberOctaves; ++o)
    {
        for (size_t l = 0; l < levelsPerOctave; ++l)
        {
            img[i] = opencl.copyImageFromDevice(*images[o], l);
            imgGx[i] = opencl.copyImageFromDevice(*imagesGx[o], l);
            imgGy[i] = opencl.copyImageFromDevice(*imagesGy[o], l);
            ++i;
        }
    }

    cv::Mat testGx;
    cv::sepFilter2D(img[0], testGx, CV_32FC1, Gx2, Gx1);

    cv::Mat testGy;
    cv::filter2D(img[0], testGy, CV_32FC1, Gy);
}

std::string PyramidCubes::name()
{
    return "Cube pyramid";
}

void PyramidCubes::createPyramid()
{
    images.resize(numberOctaves);
    imagesGx.resize(numberOctaves);
    imagesGy.resize(numberOctaves);

    // Allocate global memory on the device
    images[0] = std::make_shared<cl::Image2DArray>(opencl.getContext(), CL_MEM_READ_ONLY, cl::ImageFormat(CL_R, CL_FLOAT), levelsPerOctave, img.cols, img.rows, 0, 0);

    size_t cols = static_cast<size_t>(img.cols);
    size_t rows = static_cast<size_t>(img.rows);

    // Copy the data to the GPU
    cl::Event lastEvent;
    std::array<size_t, 3> origin = { 0, 0, 0 };
    std::array<size_t, 3> imgSize = { cols, rows, 1 };
    opencl.getQueue().enqueueWriteImage(*images[0], CL_NON_BLOCKING, origin, imgSize, img.cols * sizeof(float), 0, img.data, nullptr, &lastEvent);

    for (size_t i = 0; i < images.size(); ++i)
    {
        lastEvent = kernelFilter.runCopyInsideCube(images[i]);
        kernelFilter.addEvent(lastEvent);

        //cl::Event eventCopy;
        //std::array<size_t, 3> originSource = { 0, 0, 0 };
        //std::array<size_t, 3> originTarget = { 0, 0, 1 };
        //std::array<size_t, 3> copySize = { 10, 10, 0 };
        //std::vector<cl::Event> events = { lastEvent };
        //opencl.getQueue().enqueueCopyImage(*images[i], *images[i], originSource, originTarget, copySize, &events, &eventCopy);

        //cl::Event eventCopy2;
        //std::array<size_t, 3> originSource2 = { 0, 0, 1 };
        //std::array<size_t, 3> originTarget2 = { 0, 0, 2 };
        //std::vector<cl::Event> events2 = { eventCopy };
        //opencl.getQueue().enqueueCopyImage(*images[i], *images[i], originSource2, originTarget2, imgSize, &events2, &eventCopy2);

        //cl::Event eventCopy3;
        //std::array<size_t, 3> originSource3 = { 0, 0, 2 };
        //std::array<size_t, 3> originTarget3 = { 0, 0, 3 };
        //std::vector<cl::Event> events3 = { eventCopy2 };
        //opencl.getQueue().enqueueCopyImage(*images[i], *images[i], originSource3, originTarget3, imgSize, &events3, &eventCopy3);

        //kernelFilter.addEvent(eventCopy3);

        if (i < images.size() - 1)
        {
            lastEvent = kernelFilter.runHalfsampleImage(*images[i], images[i + 1]);
            kernelFilter.addEvent(lastEvent);
        }
    }
}

void PyramidCubes::calcDerivativesSingleSeparation()
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

void PyramidCubes::calcDerivativesSingle()
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

void PyramidCubes::calcDerivativesSingleLocal()
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
