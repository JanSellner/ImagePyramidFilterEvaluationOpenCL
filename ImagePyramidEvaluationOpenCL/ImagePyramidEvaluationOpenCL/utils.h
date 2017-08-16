#pragma once

#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>

/* ************************************************************************* */
/**
* @brief Compute derivative kernels for sizes different than 3
* @param _kx Horizontal kernel ues
* @param _ky Vertical kernel values
* @param dx Derivative order in X-direction (horizontal)
* @param dy Derivative order in Y-direction (vertical)
* @param scale_ Scale factor or derivative size
*/
inline void compute_derivative_kernels(cv::OutputArray _kx, cv::OutputArray _ky, int dx, int dy, int scale)
{
    int ksize = 3 + 2 * (scale - 1);

    // The standard Scharr kernel
    if (scale == 1)
    {
        getDerivKernels(_kx, _ky, dx, dy, 0, true, CV_32F);
        return;
    }

    _kx.create(ksize, 1, CV_32F, -1, true);
    _ky.create(ksize, 1, CV_32F, -1, true);
    cv::Mat kx = _kx.getMat();
    cv::Mat ky = _ky.getMat();

    float w = 10.0f / 3.0f;
    float norm = 1.0f / (2.0f*scale*(w + 2.0f));

    for (int k = 0; k < 2; k++)
    {
        cv::Mat* kernel = k == 0 ? &kx : &ky;
        int order = k == 0 ? dx : dy;
        std::vector<float> kerI(ksize, 0.0f);

        if (order == 0)
        {
            kerI[0] = norm, kerI[ksize / 2] = w*norm, kerI[ksize - 1] = norm;
        }
        else if (order == 1)
        {
            kerI[0] = -1, kerI[ksize / 2] = 0, kerI[ksize - 1] = 1;
        }

        cv::Mat temp(kernel->rows, kernel->cols, CV_32F, &kerI[0]);
        temp.copyTo(*kernel);
    }
}

/* ************************************************************************* */
/**
* @brief Exponentiation by squaring
* @param flt Exponentiation base
* @return dst Exponentiation value
*/
inline int fastpow(int base, int exp)
{
    int res = 1;
    while (exp > 0)
    {
        if (exp & 1)
        {
            exp--;
            res *= base;
        }
        else
        {
            exp /= 2;
            base *= base;
        }
    }
    return res;
}

inline int fRound(float flt)
{
    return static_cast<int>(flt + 0.5f);
}


inline void sepGaussKernels(cv::Mat& filterKernelX, cv::Mat& filterKernelY, const double sigma)
{
    int size = static_cast<int>(ceil(2.0f * (1.0f + (sigma - 0.8f) / 0.3f)));
    if (size % 2 == 0)
    {
        size += 1;
    }

    filterKernelX = cv::getGaussianKernel(size, sigma, CV_32F);
    filterKernelY = filterKernelX.t();
}
