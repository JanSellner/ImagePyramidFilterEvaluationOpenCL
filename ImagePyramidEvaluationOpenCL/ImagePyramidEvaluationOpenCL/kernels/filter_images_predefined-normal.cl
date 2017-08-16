/* This file is generated. Do not modify. */

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_Gx_3x3):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_Gx_3x3(read_only image2d_t imgIn,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

	coordCurrent.y = coordBase.y + -1;
	coordCurrent.x = coordBase.x + -1;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -3.0f;
	coordCurrent.x = coordBase.x + 1;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 3.0f;
	coordCurrent.y = coordBase.y;
	coordCurrent.x = coordBase.x + -1;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -10.0f;
	coordCurrent.x = coordBase.x + 1;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 10.0f;
	coordCurrent.y = coordBase.y + 1;
	coordCurrent.x = coordBase.x + -1;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -3.0f;
	coordCurrent.x = coordBase.x + 1;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 3.0f;

    return sum;
}

/**
 * Filter kernel for a single filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_Gx_3x3(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_Gx_3x3(imgIn, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_Gx_5x5):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_Gx_5x5(read_only image2d_t imgIn,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

	coordCurrent.y = coordBase.y + -2;
	coordCurrent.x = coordBase.x + -2;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -0.0468750037f;
	coordCurrent.x = coordBase.x + 2;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 0.0468750037f;
	coordCurrent.y = coordBase.y;
	coordCurrent.x = coordBase.x + -2;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -0.156250015f;
	coordCurrent.x = coordBase.x + 2;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 0.156250015f;
	coordCurrent.y = coordBase.y + 2;
	coordCurrent.x = coordBase.x + -2;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -0.0468750037f;
	coordCurrent.x = coordBase.x + 2;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 0.0468750037f;

    return sum;
}

/**
 * Filter kernel for a single filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_Gx_5x5(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_Gx_5x5(imgIn, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_Gx_7x7):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_Gx_7x7(read_only image2d_t imgIn,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

	coordCurrent.y = coordBase.y + -3;
	coordCurrent.x = coordBase.x + -3;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -0.0312500037f;
	coordCurrent.x = coordBase.x + 3;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 0.0312500037f;
	coordCurrent.y = coordBase.y;
	coordCurrent.x = coordBase.x + -3;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -0.104166679f;
	coordCurrent.x = coordBase.x + 3;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 0.104166679f;
	coordCurrent.y = coordBase.y + 3;
	coordCurrent.x = coordBase.x + -3;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -0.0312500037f;
	coordCurrent.x = coordBase.x + 3;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 0.0312500037f;

    return sum;
}

/**
 * Filter kernel for a single filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_Gx_7x7(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_Gx_7x7(imgIn, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_Gx_9x9):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_Gx_9x9(read_only image2d_t imgIn,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

	coordCurrent.y = coordBase.y + -4;
	coordCurrent.x = coordBase.x + -4;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -0.0234375019f;
	coordCurrent.x = coordBase.x + 4;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 0.0234375019f;
	coordCurrent.y = coordBase.y;
	coordCurrent.x = coordBase.x + -4;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -0.0781250075f;
	coordCurrent.x = coordBase.x + 4;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 0.0781250075f;
	coordCurrent.y = coordBase.y + 4;
	coordCurrent.x = coordBase.x + -4;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -0.0234375019f;
	coordCurrent.x = coordBase.x + 4;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 0.0234375019f;

    return sum;
}

/**
 * Filter kernel for a single filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_Gx_9x9(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_Gx_9x9(imgIn, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_Gy_3x3):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_Gy_3x3(read_only image2d_t imgIn,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

	coordCurrent.y = coordBase.y + -1;
	coordCurrent.x = coordBase.x + -1;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -3.0f;
	coordCurrent.x = coordBase.x;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -10.0f;
	coordCurrent.x = coordBase.x + 1;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -3.0f;
	coordCurrent.y = coordBase.y + 1;
	coordCurrent.x = coordBase.x + -1;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 3.0f;
	coordCurrent.x = coordBase.x;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 10.0f;
	coordCurrent.x = coordBase.x + 1;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 3.0f;

    return sum;
}

/**
 * Filter kernel for a single filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_Gy_3x3(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_Gy_3x3(imgIn, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_Gy_5x5):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_Gy_5x5(read_only image2d_t imgIn,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

	coordCurrent.y = coordBase.y + -2;
	coordCurrent.x = coordBase.x + -2;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -0.0468750037f;
	coordCurrent.x = coordBase.x;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -0.156250015f;
	coordCurrent.x = coordBase.x + 2;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -0.0468750037f;
	coordCurrent.y = coordBase.y + 2;
	coordCurrent.x = coordBase.x + -2;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 0.0468750037f;
	coordCurrent.x = coordBase.x;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 0.156250015f;
	coordCurrent.x = coordBase.x + 2;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 0.0468750037f;

    return sum;
}

/**
 * Filter kernel for a single filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_Gy_5x5(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_Gy_5x5(imgIn, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_Gy_7x7):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_Gy_7x7(read_only image2d_t imgIn,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

	coordCurrent.y = coordBase.y + -3;
	coordCurrent.x = coordBase.x + -3;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -0.0312500037f;
	coordCurrent.x = coordBase.x;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -0.104166679f;
	coordCurrent.x = coordBase.x + 3;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -0.0312500037f;
	coordCurrent.y = coordBase.y + 3;
	coordCurrent.x = coordBase.x + -3;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 0.0312500037f;
	coordCurrent.x = coordBase.x;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 0.104166679f;
	coordCurrent.x = coordBase.x + 3;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 0.0312500037f;

    return sum;
}

/**
 * Filter kernel for a single filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_Gy_7x7(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_Gy_7x7(imgIn, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_Gy_9x9):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_Gy_9x9(read_only image2d_t imgIn,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

	coordCurrent.y = coordBase.y + -4;
	coordCurrent.x = coordBase.x + -4;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -0.0234375019f;
	coordCurrent.x = coordBase.x;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -0.0781250075f;
	coordCurrent.x = coordBase.x + 4;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * -0.0234375019f;
	coordCurrent.y = coordBase.y + 4;
	coordCurrent.x = coordBase.x + -4;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 0.0234375019f;
	coordCurrent.x = coordBase.x;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 0.0781250075f;
	coordCurrent.x = coordBase.x + 4;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum += color * 0.0234375019f;

    return sum;
}

/**
 * Filter kernel for a single filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_Gy_9x9(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_Gy_9x9(imgIn, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_GxGy_3x3):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_GxGy_3x3(read_only image2d_t imgIn,
                            const int2 coordBase,
                            const int border)
{
    type_double sum = (type_double)(0.0f, 0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

	coordCurrent.y = coordBase.y + -1;
	coordCurrent.x = coordBase.x + -1;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * -3.0f;
	sum.y += color * -3.0f;
	coordCurrent.x = coordBase.x;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.y += color * -10.0f;
	coordCurrent.x = coordBase.x + 1;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * 3.0f;
	sum.y += color * -3.0f;
	coordCurrent.y = coordBase.y;
	coordCurrent.x = coordBase.x + -1;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * -10.0f;
	coordCurrent.x = coordBase.x + 1;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * 10.0f;
	coordCurrent.y = coordBase.y + 1;
	coordCurrent.x = coordBase.x + -1;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * -3.0f;
	sum.y += color * 3.0f;
	coordCurrent.x = coordBase.x;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.y += color * 10.0f;
	coordCurrent.x = coordBase.x + 1;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * 3.0f;
	sum.y += color * 3.0f;

    return sum;
}

/**
 * Filter kernel for a double filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_GxGy_3x3(read_only image2d_t imgIn,
                              write_only image2d_t imgOut1,
                              write_only image2d_t imgOut2,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_GxGy_3x3(imgIn, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_GxGy_5x5):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_GxGy_5x5(read_only image2d_t imgIn,
                            const int2 coordBase,
                            const int border)
{
    type_double sum = (type_double)(0.0f, 0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

	coordCurrent.y = coordBase.y + -2;
	coordCurrent.x = coordBase.x + -2;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * -0.0468750037f;
	sum.y += color * -0.0468750037f;
	coordCurrent.x = coordBase.x;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.y += color * -0.156250015f;
	coordCurrent.x = coordBase.x + 2;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * 0.0468750037f;
	sum.y += color * -0.0468750037f;
	coordCurrent.y = coordBase.y;
	coordCurrent.x = coordBase.x + -2;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * -0.156250015f;
	coordCurrent.x = coordBase.x + 2;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * 0.156250015f;
	coordCurrent.y = coordBase.y + 2;
	coordCurrent.x = coordBase.x + -2;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * -0.0468750037f;
	sum.y += color * 0.0468750037f;
	coordCurrent.x = coordBase.x;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.y += color * 0.156250015f;
	coordCurrent.x = coordBase.x + 2;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * 0.0468750037f;
	sum.y += color * 0.0468750037f;

    return sum;
}

/**
 * Filter kernel for a double filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_GxGy_5x5(read_only image2d_t imgIn,
                              write_only image2d_t imgOut1,
                              write_only image2d_t imgOut2,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_GxGy_5x5(imgIn, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_GxGy_7x7):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_GxGy_7x7(read_only image2d_t imgIn,
                            const int2 coordBase,
                            const int border)
{
    type_double sum = (type_double)(0.0f, 0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

	coordCurrent.y = coordBase.y + -3;
	coordCurrent.x = coordBase.x + -3;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * -0.0312500037f;
	sum.y += color * -0.0312500037f;
	coordCurrent.x = coordBase.x;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.y += color * -0.104166679f;
	coordCurrent.x = coordBase.x + 3;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * 0.0312500037f;
	sum.y += color * -0.0312500037f;
	coordCurrent.y = coordBase.y;
	coordCurrent.x = coordBase.x + -3;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * -0.104166679f;
	coordCurrent.x = coordBase.x + 3;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * 0.104166679f;
	coordCurrent.y = coordBase.y + 3;
	coordCurrent.x = coordBase.x + -3;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * -0.0312500037f;
	sum.y += color * 0.0312500037f;
	coordCurrent.x = coordBase.x;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.y += color * 0.104166679f;
	coordCurrent.x = coordBase.x + 3;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * 0.0312500037f;
	sum.y += color * 0.0312500037f;

    return sum;
}

/**
 * Filter kernel for a double filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_GxGy_7x7(read_only image2d_t imgIn,
                              write_only image2d_t imgOut1,
                              write_only image2d_t imgOut2,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_GxGy_7x7(imgIn, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_GxGy_9x9):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_GxGy_9x9(read_only image2d_t imgIn,
                            const int2 coordBase,
                            const int border)
{
    type_double sum = (type_double)(0.0f, 0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

	coordCurrent.y = coordBase.y + -4;
	coordCurrent.x = coordBase.x + -4;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * -0.0234375019f;
	sum.y += color * -0.0234375019f;
	coordCurrent.x = coordBase.x;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.y += color * -0.0781250075f;
	coordCurrent.x = coordBase.x + 4;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * 0.0234375019f;
	sum.y += color * -0.0234375019f;
	coordCurrent.y = coordBase.y;
	coordCurrent.x = coordBase.x + -4;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * -0.0781250075f;
	coordCurrent.x = coordBase.x + 4;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * 0.0781250075f;
	coordCurrent.y = coordBase.y + 4;
	coordCurrent.x = coordBase.x + -4;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * -0.0234375019f;
	sum.y += color * 0.0234375019f;
	coordCurrent.x = coordBase.x;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.y += color * 0.0781250075f;
	coordCurrent.x = coordBase.x + 4;
	coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
	color = read_imagef(imgIn, sampler, coordBorder).x;
	sum.x += color * 0.0234375019f;
	sum.y += color * 0.0234375019f;

    return sum;
}

/**
 * Filter kernel for a double filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_GxGy_9x9(read_only image2d_t imgIn,
                              write_only image2d_t imgOut1,
                              write_only image2d_t imgOut2,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_GxGy_9x9(imgIn, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}
