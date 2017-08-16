#include "OpenCLInterface.h"
#include "general.h"
#include "settings.h"

OpenCLInterface::OpenCLInterface()
{}

OpenCLInterface::~OpenCLInterface()
{}

void OpenCLInterface::selectDevice()
{
#ifdef DEBUG_INTEL
    device = chooseDevice();
#else
    device = selectFirstGPU();
#endif
}

void OpenCLInterface::init()
{
    // The context is responsible for the host-device interaction and manages the interacting objects (program, kernel, queue)
    context = cl::Context(device);
	
	// Every command is enqueued in this queue and then executed by the runtime on the device

	std::string deviceNameLower(device.getInfo<CL_DEVICE_VENDOR>());
	std::transform(deviceNameLower.begin(), deviceNameLower.end(), deviceNameLower.begin(), ::tolower);

	if (deviceNameLower.find("nvidia") != deviceNameLower.npos)
	{
		cl_int error;
		cl_command_queue_properties properties = 0;

        queue = clCreateCommandQueue(context(), device(), properties, &error);
        queue2 = clCreateCommandQueue(context(), device(), properties, &error);
	}
	else
	{
        queue = cl::CommandQueue(context, device);
        queue2 = cl::CommandQueue(context, device);
	}
}

cl::Event OpenCLInterface::createImageOnDevice(const cv::Mat& img, cl::Image2D& imgOpencl) const
{
    // Allocate global memory on the device
    imgOpencl = cl::Image2D(context, CL_MEM_READ_ONLY, cl::ImageFormat(CL_R, CL_FLOAT), img.cols, img.rows);

    // Copy the data to the GPU
    cl::Event eventImage;
    std::array<size_t, 3> origin = { 0, 0, 0 };
    std::array<size_t, 3> imgSize = { static_cast<size_t>(img.cols), static_cast<size_t>(img.rows), 1 };
    queue.enqueueWriteImage(imgOpencl, CL_NON_BLOCKING, origin, imgSize, img.cols * sizeof(float), 0, img.data, nullptr, &eventImage);

    return eventImage;
}

cl::Event OpenCLInterface::copyImageOnDevice(const cl::Image2D& imgSrc, SPImage2D& imgDst, const cl::Event& event)
{
    const size_t rows = imgSrc.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = imgSrc.getImageInfo<CL_IMAGE_WIDTH>();

    imgDst = std::make_shared<cl::Image2D>(context, CL_MEM_READ_WRITE, cl::ImageFormat(CL_R, CL_FLOAT), cols, rows);

    cl::Event eventCopy;
    std::array<size_t, 3> origin = { 0, 0, 0 };
    std::array<size_t, 3> imgSize = { cols, rows, 1 };
    std::vector<cl::Event> events = { event };
    queue.enqueueCopyImage(imgSrc, *imgDst, origin, origin, imgSize, &events, &eventCopy);
    
    return eventCopy;
}

cv::Mat OpenCLInterface::copyImageFromDevice(const cl::Image2D& img) const
{
    const size_t rows = img.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = img.getImageInfo<CL_IMAGE_WIDTH>();

    std::array<size_t, 3> origin = { 0, 0, 0 };
    std::array<size_t, 3> imgSize = { cols, rows, 1 };
    cv::Mat imgHost(static_cast<int>(rows), static_cast<int>(cols), CV_32FC1);
    
    ASSERT(imgHost.isContinuous(), "Not enough memory available to store the image continuously in memory");

    queue.finish(); // Wair until every operation finished before reading the image back from the device
    queue.enqueueReadImage(img, true, origin, imgSize, cols * sizeof(float), 0, imgHost.data);
    queue.finish();

    return imgHost;
}

cv::Mat OpenCLInterface::copyImageFromDevice(const cl::Image2DArray& img, size_t idx) const
{
    const size_t rows = img.getImageInfo<CL_IMAGE_HEIGHT>();
    const size_t cols = img.getImageInfo<CL_IMAGE_WIDTH>();

    std::array<size_t, 3> origin = { 0, 0, idx };
    std::array<size_t, 3> imgSize = { cols, rows, 1 };
    cv::Mat imgHost(static_cast<int>(rows), static_cast<int>(cols), CV_32FC1);

    ASSERT(imgHost.isContinuous(), "Not enough memory available to store the image continuously in memory");

    queue.finish(); // Wair until every operation finished before reading the image back from the device
    queue.enqueueReadImage(img, true, origin, imgSize, cols * sizeof(float), 0, imgHost.data);
    queue.finish();

    return imgHost;
}

cl::Device& OpenCLInterface::getDevice()
{
    return device;
}

cl::Context& OpenCLInterface::getContext()
{
    return context;
}

cl::CommandQueue& OpenCLInterface::getQueue()
{
    return queue;
}

cl::CommandQueue& OpenCLInterface::getQueue2()
{
    return queue2;
}

std::string& OpenCLInterface::getBuildOptions()
{
    return buildOptions;
}

std::string& OpenCLInterface::getBuildOptionsDebug()
{
    return buildOptionsDebug;
}
