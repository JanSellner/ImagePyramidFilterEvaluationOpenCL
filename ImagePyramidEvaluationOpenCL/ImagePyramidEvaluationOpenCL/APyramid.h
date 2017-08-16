#pragma once

#include "OpenCLInterface.h"
#include <string>
#include "settings.h"

class APyramid
{
public:
    enum Method
    {
        SINGLE_SEPARATION = 1,
        SINGLE = 2,
        DOUBLE = 3,
        DOUBLE_SEPARATION = 4,
        SINGLE_LOCAL = 6,
        SINGLE_SEPARATION_LOCAL = 7,
        DOUBLE_LOCAL = 9,
        SINGLE_PREDEFINED = 11,
        DOUBLE_PREDEFINED = 12,
        SINGLE_PREDEFINED_LOCAL = 13,
        DOUBLE_PREDEFINED_LOCAL = 14
    };

    static std::string methodToString(Method m)
    {
        switch (m)
        {
            case SINGLE_SEPARATION: return "singleSeparation";
            case SINGLE: return "single";
            case DOUBLE: return "double";
            case DOUBLE_SEPARATION: return "doubleSeparation";
            case SINGLE_LOCAL: return "singleLocal";
            case SINGLE_SEPARATION_LOCAL: return "singleSeparationLocal";
            case DOUBLE_LOCAL: return "doubleLocal";
            case SINGLE_PREDEFINED: return "singlePredefined";
            case DOUBLE_PREDEFINED: return "doublePredefined";
            case SINGLE_PREDEFINED_LOCAL: return "singlePredefinedLocal";
            case DOUBLE_PREDEFINED_LOCAL: return "doublePredefinedLocal";
            default: return "";
        }
    }

    struct Settings
    {
        Method method = SINGLE_SEPARATION;
        int sigmaSize = 1;
    };

public:
    explicit APyramid(const cv::Mat& img);
    virtual ~APyramid();

    virtual void init() = 0;
    virtual long long startFilterTest() = 0;
    virtual void readImages() = 0;
    virtual std::string name() = 0;

    void setSettings(const Settings& settings);

protected:
    cv::Mat img;
    OpenCLInterface opencl;
    Settings settings;
    int pyramidSize = 16;
    int numberOctaves = 4;
    int levelsPerOctave = 4;

    cv::Mat Gx1;
    cv::Mat Gx2;
    cv::Mat Gy1;
    cv::Mat Gy2;

    cv::Mat Gx;
    cv::Mat Gy;
};
