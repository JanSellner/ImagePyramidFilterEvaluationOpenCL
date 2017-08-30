# ImagePyramidFilterEvaluationOpenCL
Evaluation of different filter operations and different storage types (image, cube, buffer, image buffer) in OpenCL. This is the repository for two corresponding blog articles:
- [Performance evaluation of image convolution with gradient filters in OpenCL](https://milania.de/blog/Performance_evaluation_of_image_convolution_with_gradient_filters_in_OpenCL): assesses the performance of filter operations implemented in different ways.
- [Buffer vs. image performance for applying filters to an image pyramid in OpenCL](https://milania.de/blog/Buffer_vs._image_performance_for_applying_filters_to_an_image_pyramid_in_OpenCL): focuses on different storage types which are best suited for an image pyramid.

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
