#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <map>
#include "PyramidImages.h"
#include "PyramidCubes.h"
#include "PyramidBuffer.h"
#include "settings.h"
#include "utils.h"
#include <iomanip>

struct TestResults
{
    int sigmaSize;
    std::vector<long long> times;
};

void testBatch(APyramid& pyramid)
{
    std::vector<APyramid::Method> methods = {
        // Default cases
        APyramid::SINGLE ,
        APyramid::SINGLE_LOCAL,
        APyramid::SINGLE_SEPARATION,
        APyramid::DOUBLE,

        // Selected combinations
        APyramid::SINGLE_PREDEFINED,
        APyramid::SINGLE_PREDEFINED_LOCAL,
        APyramid::DOUBLE_PREDEFINED,
        APyramid::DOUBLE_PREDEFINED_LOCAL,
        APyramid::DOUBLE_LOCAL
    };

    std::vector<int> sigmaSizes = { 1, 2, 3, 4};
    int iterations = 20;

    std::map<APyramid::Method, std::vector<TestResults>> results;

    APyramid::Settings settings;
    pyramid.init();

    for (auto method : methods)
    {
        for (int sigmaSize : sigmaSizes)
        {
            TestResults testResults;
            testResults.sigmaSize = sigmaSize;

            for (size_t i = 0; i < iterations; ++i)
            {
                settings.method = method;
                settings.sigmaSize = sigmaSize;
                pyramid.setSettings(settings);

                long long time = pyramid.startFilterTest();

                testResults.times.push_back(time);
            }
            
            results[method].push_back(testResults);
        }
    }

    std::cout << "Test of " << pyramid.name() << std::endl;
    std::cout << "--- Mathematica output ---" << std::endl;
    for (auto pair : results)
    {
        std::cout << APyramid::methodToString(pair.first) << "={";

        for (size_t i = 0; i < pair.second.size(); ++i)
        {
            const TestResults& testResults = pair.second[i];

            std::cout << "{";

            for (size_t t = 0; t < testResults.times.size(); ++t)
            {
                std::cout << testResults.times[t];

                if (t < testResults.times.size() - 1)
                {
                    std::cout << ",";
                }
            }

            std::cout << "}";

            if (i < pair.second.size() - 1)
            {
                std::cout << ",";
            }
        }

        std::cout << "};" << std::endl;
    }

    std::cout << "--- JavaScript output ---" << std::endl;
    for (auto pair : results)
    {
        std::cout << "var " << APyramid::methodToString(pair.first) << "Mean = [";

        for (size_t i = 0; i < pair.second.size(); ++i)
        {
            const TestResults& testResults = pair.second[i];

            double avg = 0.0;
            for (size_t t = 0; t < testResults.times.size(); ++t)
            {
                avg += testResults.times[t];
            }

            std::cout << avg / testResults.times.size();

            if (i < pair.second.size() - 1)
            {
                std::cout << ", ";
            }
        }

        std::cout << "];" << std::endl;
    }

    std::cout << "done" << std::endl;
}

void test(APyramid& pyramid)
{
    APyramid::Settings settings;
    settings.method = APyramid::DOUBLE_PREDEFINED_LOCAL;
    settings.sigmaSize = 2;
    pyramid.setSettings(settings);

    pyramid.init();
    
    long long time = pyramid.startFilterTest();
    std::cout << "time: " << time << std::endl;
    
    pyramid.readImages();
}

void generateScharrKernels()
{
    std::fstream fileKernels("kernels/derivative_kernels.pl", std::ios::out);

    fileKernels << "our %kernels;" << std::endl;

    const auto printKernel = [&](const std::string& name, const cv::Mat& kernel)
    {
        fileKernels << "$kernels{'" << name << "'} = [";

        const float* kernelPtr = kernel.ptr<float>(0);

        for (size_t i = 0; i < kernel.rows * kernel.cols; ++i)
        {
            // Print float with full precision: https://stackoverflow.com/questions/554063/how-do-i-print-a-double-value-with-full-precision-using-cout
            fileKernels << std::setprecision(std::numeric_limits<float>::max_digits10) << kernelPtr[i];
            if (i < kernel.rows * kernel.cols - 1)
            {
                fileKernels << ", ";
            }
        }

        fileKernels << "];" << std::endl;
    };

    const cv::Mat filterKernelScharrGx = (cv::Mat_<float>(3, 3) <<
                                          -3, 0, 3,
                                          -10, 0, 10,
                                          -3, 0, 3);
    const cv::Mat filterKernelScharrGy = (cv::Mat_<float>(3, 3) <<
                                          -3, -10, -3,
                                          0, 0, 0,
                                          3, 10, 3);

    printKernel("Gx_3x3", filterKernelScharrGx);
    printKernel("Gy_3x3", filterKernelScharrGy);

    for (int sigmaSize = 2; sigmaSize <= 4; ++sigmaSize)
    {
        cv::Mat Gx1, Gx2;
        compute_derivative_kernels(Gx1, Gx2, 0, 1, sigmaSize);  // x and y are swapped in this function; therefore, (0, 1) is the x-direction (left to right)
        cv::Mat Gy1, Gy2;
        compute_derivative_kernels(Gy1, Gy2, 1, 0, sigmaSize);

        printKernel("Gx_" + std::to_string(Gx1.rows) + "x" + std::to_string(Gx1.rows), Gx1 * Gx2.t());
        printKernel("Gy_" + std::to_string(Gy1.rows) + "x" + std::to_string(Gy1.rows), Gy1 * Gy2.t());
    }

    fileKernels.flush();
    fileKernels.close();
}

int main()
{
    //generateScharrKernels();

#ifdef DEBUG_INTEL
    cv::Mat img = cv::imread("../../test_images/tomo.jpg");
#else
    //cv::Mat img = cv::imread("../../test_images/tomo.jpg");
    cv::Mat img = cv::imread("../../test_images/GaussianScaleSpace_TrissFullResolution.jpg");
#endif
    
    cv::Mat imgGray;
    cv::cvtColor(img, imgGray, cv::COLOR_BGR2GRAY);
    imgGray.convertTo(imgGray, CV_32FC1, 1.0 / 255.0);

    PyramidImages pyramid(imgGray);
    //PyramidCubes pyramid(imgGray);
    //PyramidBuffer pyramid(imgGray);

    testBatch(pyramid);
    //test(pyramid);
 
    return 0;
}
