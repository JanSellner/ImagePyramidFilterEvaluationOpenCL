# ImagePyramidFilterEvaluationOpenCL
Evaluation of different filter operation and different image types (image, cube, buffer) in OpenCL.

# Build instruction
- Install Visual Studio 2015
- Install OpenCV (e.g. like described in [this article](https://milania.de/blog/Building_and_configuring_OpenCV_in_Visual_Studio_2015_with_source_code_mapping))
- Install the [Intel SDK for OpenCL](https://software.intel.com/en-us/intel-opencl/download)
- Build and run the solution
  - Start point is the file [main.cpp](ImagePyramidEvaluationOpenCL/ImagePyramidEvaluationOpenCL/main.cpp) where you can switch between the different image types and set other test settings
  - Use `test(pyramid)` to test if the implementation works without running any performance tests
  - Use `testBatch(pyramid);` to start the performance tests

# Filter generation
The OpenCL kernel code which implements the filters is generated via a Perl script. Running [this script](ImagePyramidEvaluationOpenCL/ImagePyramidEvaluationOpenCL/kernels/generate_kernels.pl) (`run generate_kernels.pl` in the `kernels` folder) uses the `.base` files as basis and generates all different filter sizes as well as single, double and predefined filters. The generated files are included in the [`filter_images.cl`](ImagePyramidEvaluationOpenCL/ImagePyramidEvaluationOpenCL/kernels/filter_images.cl) file (when using the `image2d_t` data type) which is passed to the OpenCL runtime.
