#pragma once

#include <vector>
#include <string>
#include "opencl_common.h"
#include "AOpenCLInterface.h"
#include <memory>

using SPImage2D = std::shared_ptr<cl::Image2D>;
using SPImage2DArray = std::shared_ptr<cl::Image2DArray>;

template<class Derived>
class AKernel
{
public:
    AKernel(AOpenCLInterface* const opencl, cl::Program* const program)
        : opencl(opencl),
          program(program),
          device(&opencl->getDevice()),
          context(&opencl->getContext()),
          queue(&opencl->getQueue()),
          queue2(&opencl->getQueue2())
    {}

    virtual ~AKernel()
    {}

    void addEvent(const cl::Event& event)
    {
        events.push_back(event);
    }

    void setQueue(cl::CommandQueue* queue)
    {
        this->queue = queue;
    }

    void setQueue2(cl::CommandQueue* queue2)
    {
        this->queue2 = queue2;
    }

    static std::string kernelSource()
    {
        return Derived::kernelSource();
    }

protected:
    AOpenCLInterface* opencl;
    cl::Program* program;
    cl::Device* device;
    cl::Context* context;
    cl::CommandQueue* queue;
    cl::CommandQueue* queue2;
    std::vector<cl::Event> events;
};
