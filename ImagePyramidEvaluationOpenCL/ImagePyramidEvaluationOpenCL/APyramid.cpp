#include "APyramid.h"
#include "utils.h"

APyramid::APyramid(const cv::Mat& img)
    : img(img)
{}

APyramid::~APyramid()
{}

void APyramid::setSettings(const Settings& settings)
{
    this->settings = settings;

    Gx1.release();
    Gx2.release();
    Gy1.release();
    Gy2.release();
    Gx.release();
    Gy.release();

    if (settings.sigmaSize == 1)
    {
        Gx1 = (cv::Mat_<float>(3, 1) << 3, 10, 3);
        Gx2 = (cv::Mat_<float>(1, 3) << -1, 0, 1);
        Gy1 = (cv::Mat_<float>(3, 1) << -1, 0, 1);
        Gy2 = (cv::Mat_<float>(1, 3) << 3, 10, 3);

        Gx = Gx1 * Gx2;
        Gy = Gy1 * Gy2;
    }
    else
    {
        compute_derivative_kernels(Gx1, Gx2, 0, 1, settings.sigmaSize);  // x and y are swapped in this function; therefore, (0, 1) is the x-direction (left to right)
        compute_derivative_kernels(Gy1, Gy2, 1, 0, settings.sigmaSize);

        Gx2 = Gx2.t();
        Gy2 = Gy2.t();

        Gx = Gx1 * Gx2;
        Gy = Gy1 * Gy2;
    }

    std::cout << "kernel size: " << Gx.cols << " x " << Gx.rows << std::endl;
}
