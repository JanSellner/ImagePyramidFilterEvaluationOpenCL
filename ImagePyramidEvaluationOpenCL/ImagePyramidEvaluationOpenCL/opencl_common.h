#ifndef _OPENCL_COMMON_H_
#define _OPENCL_COMMON_H_

#include <iostream>
#include <fstream>
#include <vector>
#include <string>

#define CL_USE_DEPRECATED_OPENCL_1_2_APIS  // Necessary to work on Nvidia cards
#define CL_HPP_ENABLE_EXCEPTIONS
#define CL_HPP_TARGET_OPENCL_VERSION 200
#include <CL/cl2.hpp>

inline cl::Device chooseDevice(const int idPlattform = -1, const int idDevice = -1)
{
	std::vector<cl::Platform> allPlattforms;
	cl::Platform::get(&allPlattforms);

    if (idPlattform >= 0 && idDevice >= 0)
    {
        cl::Platform usedPlatform = allPlattforms[idPlattform];
        std::vector<cl::Device> allDevices;
        usedPlatform.getDevices(CL_DEVICE_TYPE_ALL, &allDevices);

        return allDevices[idDevice];
    }

	std::cout << "Platforms" << std::endl;
	for (int i = 0; i < allPlattforms.size(); i++) {
		const cl::Platform& p = allPlattforms[i];
		std::cout << "\t" << i << ": " << p.getInfo<CL_PLATFORM_NAME>() << " - " << p.getInfo<CL_PLATFORM_VERSION>() << std::endl;
	}

	// Let the user choose the plattform
	int plattform = 0;
	while (allPlattforms.size() > 0) {
		std::cout << "Choose plattform: ";
		std::cin >> plattform;

		if (!std::cin || plattform < 0 || plattform >= allPlattforms.size()) {
			std::cout << "Invalid plattform, choose again." << std::endl;
			std::cin.sync();
			std::cin.clear();
		}
		else {
			break;
		}
	}

	cl::Platform usedPlatform = allPlattforms[plattform];

	std::vector<cl::Device> allDevices;
	usedPlatform.getDevices(CL_DEVICE_TYPE_ALL, &allDevices);

	std::cout << "Devices on plattform " << usedPlatform.getInfo<CL_PLATFORM_NAME>() << std::endl;
	for (int i = 0; i < allDevices.size(); i++) {
		const cl::Device& d = allDevices[i];
		std::cout << "\t" << i << ": " << d.getInfo<CL_DEVICE_NAME>() << " - " << d.getInfo<CL_DEVICE_VERSION>() << std::endl;
	}
	
	// Let the user choose the device
	int device = 0;
	while (allDevices.size() > 0) {
		std::cout << "Choose device: ";
		std::cin >> device;

		if (!std::cin || device < 0 || device >= allDevices.size()) {
			std::cout << "Invalid device, choose again." << std::endl;
			std::cin.sync();
			std::cin.clear();
		}
		else {
			break;
		}
	}

	return allDevices[device];
}

inline cl::Device selectFirstGPU()
{
    std::vector<cl::Platform> allPlattforms;
    cl::Platform::get(&allPlattforms);

    // Iterate over all plattforms and retrieve all devices, select the first found GPU device
    for (const cl::Platform& plattform : allPlattforms)
    {
        try
        {
            std::vector<cl::Device> allDevices;
            plattform.getDevices(CL_DEVICE_TYPE_GPU, &allDevices);

            if (allDevices.size() == 1)
            {
                std::cout << "Used platform: " << ": " << plattform.getInfo<CL_PLATFORM_NAME>() << " - " << plattform.getInfo<CL_PLATFORM_VERSION>() << std::endl;
                std::cout << "Used Device" << ": " << allDevices[0].getInfo<CL_DEVICE_NAME>() << " - " << allDevices[0].getInfo<CL_DEVICE_VERSION>() << std::endl;

                return allDevices[0];
            }
        }
        catch (const cl::Error&)
        {}
    }

    throw cl::Error(1337, "No GPU device found");
}

inline std::string getKernelSource(const std::string& filename)
{
    std::fstream kernelCode(filename, std::ios::in);
    return std::string(std::istreambuf_iterator<char>(kernelCode), std::istreambuf_iterator<char>());
}

#endif //_OPENCL_COMMON_H_
