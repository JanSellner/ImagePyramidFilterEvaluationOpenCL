#include "PyramidBuffer.h"
#include <opencv2/imgproc.hpp>

PyramidBuffer::PyramidBuffer(const cv::Mat& img)
    : APyramid(img),
      kernelFilter(&opencl, &programFilter),
      kernelFilter2(&opencl, &programFilter)
{}

PyramidBuffer::~PyramidBuffer()
{}

void PyramidBuffer::init()
{
    try
    {
        opencl.selectDevice();
        opencl.init();

        programFilter = cl::Program(opencl.getContext(), AKernel<KernelFilterBuffer<cl::Buffer>>::kernelSource());

#ifdef DEBUG_INTEL
        programFilter.build((opencl.getBuildOptions() + " -Werror -g -s kernels/filter_buffer.cl").c_str());
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

long long PyramidBuffer::startFilterTest()
{
    long long diff = 0;

    std::chrono::steady_clock::time_point begin = std::chrono::steady_clock::now();

    switch (settings.method)
    {
        //case SINGLE_SEPARATION:
        //    calcDerivativesSingleSeparation();
        //    break;
        case SINGLE:
            calcDerivativesSingle();
            break;
        case SINGLE_LOCAL:
            calcDerivativesSingleLocal();
            break;
        case SINGLE_SEPARATION_LOCAL:
            calcDerivativesSingleSeparationLocal();
            break;
        default:
            break;
    }

    opencl.getQueue().finish();

    std::chrono::steady_clock::time_point end = std::chrono::steady_clock::now();
    diff = std::chrono::duration_cast<std::chrono::milliseconds>(end - begin).count();

    return diff;
}

void PyramidBuffer::readImages()
{
    std::vector<cv::Mat> img = readImageStack(images);
    std::vector<cv::Mat> imgGx = readImageStack(imagesGx);
    std::vector<cv::Mat> imgGy = readImageStack(imagesGy);

    cv::Mat testGx;
    cv::sepFilter2D(img[0], testGx, CV_32FC1, Gx2, Gx1);

    cv::Mat testGy;
    cv::filter2D(img[0], testGy, CV_32FC1, Gy);
}

std::string PyramidBuffer::name()
{
    return "Buffer pyramid";
}

std::vector<cv::Mat> PyramidBuffer::readImageStack(const cl::Buffer& images)
{
    cv::Mat pyramid(1, totalPixels, CV_32FC1);
    opencl.getQueue().enqueueReadBuffer(images, CL_BLOCKING, 0, sizeof(float) *  totalPixels, pyramid.data);

    ASSERT(pyramid.isContinuous(), "The pyramid data must be stored continuously in memory");
    std::vector<cv::Mat> imagesVector(locationLoopup.size() + 1);

    for (size_t i = 0; i < locationLoopup.size(); ++i)
    {
        imagesVector[i] = cv::Mat(locationLoopup[i].imgHeight, locationLoopup[i].imgWidth, pyramid.type(), reinterpret_cast<float*>(pyramid.data) + locationLoopup[i].previousPixels, cv::Mat::AUTO_STEP); // Only a wrapper to the data stored in the pyramid, no data is copied
    }

    imagesVector.back() = pyramid;

    return imagesVector;
}

void PyramidBuffer::createPyramid()
{
    locationLoopup.resize(pyramidSize);
    int previousPixels = 0;
    int octave = 0;
    for (size_t i = 0; i < pyramidSize; ++i)
    {
        locationLoopup[i].imgWidth = static_cast<int>(img.cols / pow(2.0, octave));
        locationLoopup[i].imgHeight = static_cast<int>(img.rows / pow(2.0, octave));

        locationLoopup[i].previousPixels = previousPixels;
        previousPixels += locationLoopup[i].imgWidth * locationLoopup[i].imgHeight;

        if (i % 4 == 3)
        {
            ++octave;
        }
    }

    totalPixels = previousPixels;

    // Load location lookup
    bufferLocationLookup = cl::Buffer(opencl.getContext(), CL_MEM_READ_ONLY, sizeof(Lookup) * this->locationLoopup.size());
    opencl.getQueue().enqueueWriteBuffer(bufferLocationLookup, CL_BLOCKING, 0, sizeof(Lookup) *  this->locationLoopup.size(), this->locationLoopup.data());

    // Images
    images = cl::Buffer(opencl.getContext(), CL_MEM_READ_ONLY, sizeof(float) * totalPixels);
    imagesGx = cl::Buffer(opencl.getContext(), CL_MEM_WRITE_ONLY, sizeof(float) * totalPixels);
    imagesGy = cl::Buffer(opencl.getContext(), CL_MEM_WRITE_ONLY, sizeof(float) * totalPixels);

    // Copy the data to the GPU
    cl::Event lastEvent;
    opencl.getQueue().enqueueWriteBuffer(images, CL_BLOCKING, 0, sizeof(float) * img.rows * img.cols, img.data);

    for (int o = 0; o < numberOctaves; ++o)
    {
        lastEvent = kernelFilter.runCopyInsideCube(images, bufferLocationLookup, o, locationLoopup);
        kernelFilter.addEvent(lastEvent);

        if (o < numberOctaves - 1)
        {
            lastEvent = kernelFilter.runHalfsampleImage(images, bufferLocationLookup, o, locationLoopup);
            kernelFilter.addEvent(lastEvent);
        }
    }
}

void PyramidBuffer::calcDerivativesSingle()
{
    kernelFilter.setKernel1(Gx);
    kernelFilter2.setKernel1(Gy);

    kernelFilter.setBorder(cv::BORDER_DEFAULT);
    kernelFilter2.setBorder(cv::BORDER_DEFAULT);

    for (int o = 0; o < numberOctaves; ++o)
    {
        kernelFilter.runSingle(images, imagesGx, bufferLocationLookup, o, locationLoopup);
        kernelFilter2.runSingle(images, imagesGy, bufferLocationLookup, o, locationLoopup);
    }
}

void PyramidBuffer::calcDerivativesSingleLocal()
{
    kernelFilter.setKernel1(Gx);
    kernelFilter2.setKernel1(Gy);

    kernelFilter.setBorder(cv::BORDER_DEFAULT);
    kernelFilter2.setBorder(cv::BORDER_DEFAULT);

    for (int o = 0; o < numberOctaves; ++o)
    {
        kernelFilter.runSingleLocal(images, imagesGx, bufferLocationLookup, o, locationLoopup);
        kernelFilter2.runSingleLocal(images, imagesGy, bufferLocationLookup, o, locationLoopup);
    }
}

void PyramidBuffer::calcDerivativesSingleSeparationLocal()
{
    kernelFilter.setKernelSeparation1(Gx1, Gx2);
    kernelFilter2.setKernelSeparation1(Gy1, Gy2);

    kernelFilter.setBorder(cv::BORDER_DEFAULT);
    kernelFilter2.setBorder(cv::BORDER_DEFAULT);

    for (int o = 0; o < numberOctaves; ++o)
    {
        kernelFilter.runSingleSeparationLocal(images, imagesGx, bufferLocationLookup, o, locationLoopup);
        kernelFilter2.runSingleSeparationLocal(images, imagesGy, bufferLocationLookup, o, locationLoopup);
    }
}
