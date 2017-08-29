#include "PyramidImages1D.h"
#include <opencv2/imgproc.hpp>

PyramidImages1D::PyramidImages1D(const cv::Mat& img)
    : APyramid(img),
    kernelFilter(&opencl, &programFilter),
    kernelFilter2(&opencl, &programFilter)
{}

PyramidImages1D::~PyramidImages1D()
{}

void PyramidImages1D::init()
{
    try
    {
        opencl.selectDevice();
        opencl.init();

        programFilter = cl::Program(opencl.getContext(), AKernel<KernelFilterBuffer<cl::Image1DBuffer>>::kernelSource());

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

long long PyramidImages1D::startFilterTest()
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

void PyramidImages1D::readImages()
{
    std::vector<cv::Mat> img = readImageStack(image);
    std::vector<cv::Mat> imgGx = readImageStack(imageGx);
    std::vector<cv::Mat> imgGy = readImageStack(imageGy);

    cv::Mat testGx;
    cv::sepFilter2D(img[0], testGx, CV_32FC1, Gx2, Gx1);

    cv::Mat testGy;
    cv::filter2D(img[0], testGy, CV_32FC1, Gy);
}

std::string PyramidImages1D::name()
{
    return "Image1D pyramid";
}

std::vector<cv::Mat> PyramidImages1D::readImageStack(const cl::Image1DBuffer& images)
{
    cv::Mat pyramid(1, totalPixels, CV_32FC1);

    std::array<size_t, 3> origin = { 0, 0, 0 };
    std::array<size_t, 3> imgSize = { totalPixels, 1, 1 };
    opencl.getQueue().enqueueReadImage(images, CL_BLOCKING, origin, imgSize, totalPixels * sizeof(float), 0, pyramid.data);

    ASSERT(pyramid.isContinuous(), "The pyramid data must be stored continuously in memory");
    std::vector<cv::Mat> imagesVector(locationLoopup.size() + 1);

    for (size_t i = 0; i < locationLoopup.size(); ++i)
    {
        imagesVector[i] = cv::Mat(locationLoopup[i].imgHeight, locationLoopup[i].imgWidth, pyramid.type(), reinterpret_cast<float*>(pyramid.data) + locationLoopup[i].previousPixels, cv::Mat::AUTO_STEP); // Only a wrapper to the data stored in the pyramid, no data is copied
    }

    imagesVector.back() = pyramid;

    return imagesVector;
}

void PyramidImages1D::createPyramid()
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

    size_t maxBuffSize = 0;
    opencl.getDevice().getInfo(CL_DEVICE_IMAGE_MAX_BUFFER_SIZE, &maxBuffSize);

    // Images
    bufferImages = cl::Buffer(opencl.getContext(), CL_MEM_READ_ONLY, sizeof(float) * totalPixels);
    bufferImagesGx = cl::Buffer(opencl.getContext(), CL_MEM_WRITE_ONLY, sizeof(float) * totalPixels);
    bufferImagesGy = cl::Buffer(opencl.getContext(), CL_MEM_WRITE_ONLY, sizeof(float) * totalPixels);
    image = cl::Image1DBuffer(opencl.getContext(), CL_MEM_READ_ONLY, cl::ImageFormat(CL_R, CL_FLOAT), totalPixels, bufferImages);
    imageGx = cl::Image1DBuffer(opencl.getContext(), CL_MEM_READ_ONLY, cl::ImageFormat(CL_R, CL_FLOAT), totalPixels, bufferImagesGx);
    imageGy = cl::Image1DBuffer(opencl.getContext(), CL_MEM_READ_ONLY, cl::ImageFormat(CL_R, CL_FLOAT), totalPixels, bufferImagesGy);

    // Copy the data to the GPU
    cl::Event lastEvent;
    std::array<size_t, 3> origin = { 0, 0, 0 };
    std::array<size_t, 3> imgSize = { img.cols * img.rows, 1, 1 };
    opencl.getQueue().enqueueWriteImage(image, CL_BLOCKING, origin, imgSize, totalPixels * sizeof(float), 0, img.data);

    for (int o = 0; o < numberOctaves; ++o)
    {
        lastEvent = kernelFilter.runCopyInsideCube(image, bufferLocationLookup, o, locationLoopup);
        kernelFilter.addEvent(lastEvent);

        if (o < numberOctaves - 1)
        {
            lastEvent = kernelFilter.runHalfsampleImage(image, bufferLocationLookup, o, locationLoopup);
            kernelFilter.addEvent(lastEvent);
        }
    }
}

void PyramidImages1D::calcDerivativesSingle()
{
    kernelFilter.setKernel1(Gx);
    kernelFilter2.setKernel1(Gy);

    kernelFilter.setBorder(cv::BORDER_DEFAULT);
    kernelFilter2.setBorder(cv::BORDER_DEFAULT);

    for (int o = 0; o < numberOctaves; ++o)
    {
        kernelFilter.runSingle(image, imageGx, bufferLocationLookup, o, locationLoopup);
        kernelFilter2.runSingle(image, imageGy, bufferLocationLookup, o, locationLoopup);
    }
}

void PyramidImages1D::calcDerivativesSingleLocal()
{
    kernelFilter.setKernel1(Gx);
    kernelFilter2.setKernel1(Gy);

    kernelFilter.setBorder(cv::BORDER_DEFAULT);
    kernelFilter2.setBorder(cv::BORDER_DEFAULT);

    for (int o = 0; o < numberOctaves; ++o)
    {
        kernelFilter.runSingleLocal(image, imageGx, bufferLocationLookup, o, locationLoopup);
        kernelFilter2.runSingleLocal(image, imageGy, bufferLocationLookup, o, locationLoopup);
    }
}

void PyramidImages1D::calcDerivativesSingleSeparationLocal()
{
    kernelFilter.setKernelSeparation1(Gx1, Gx2);
    kernelFilter2.setKernelSeparation1(Gy1, Gy2);

    kernelFilter.setBorder(cv::BORDER_DEFAULT);
    kernelFilter2.setBorder(cv::BORDER_DEFAULT);

    for (int o = 0; o < numberOctaves; ++o)
    {
        kernelFilter.runSingleSeparationLocal(image, imageGx, bufferLocationLookup, o, locationLoopup);
        kernelFilter2.runSingleSeparationLocal(image, imageGy, bufferLocationLookup, o, locationLoopup);
    }
}
