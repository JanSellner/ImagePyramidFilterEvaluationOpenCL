/* This file is generated. Do not modify. */

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single(read_only image2d_t imgIn,
                            constant float* filterKernel,
                            const int filterRowsHalf,
                            const int filterCols,
                            const int filterColsHalf,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -filterRowsHalf; y <= filterRowsHalf; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -filterColsHalf; x <= filterColsHalf; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + filterRowsHalf) * filterCols + x + filterColsHalf;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2)
 * @param filterCols cols of the filter
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2)
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              constant float* filterKernel,
                              const int filterRowsHalf,
                              const int filterCols,
                              const int filterColsHalf,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single(imgIn, filterKernel, filterRowsHalf, filterCols, filterColsHalf, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

// Normal filter
/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_3x3):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_3x3(read_only image2d_t imgIn,
                            constant float* filterKernel,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_3x3; y <= ROWS_HALF_3x3; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_3x3; x <= COLS_HALF_3x3; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_3x3) * COLS_3x3 + x + COLS_HALF_3x3;
            sum += color * filterKernel[idx];
        }
    }

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
kernel void filter_single_3x3(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              constant float* filterKernel,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_3x3(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_5x5):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_5x5(read_only image2d_t imgIn,
                            constant float* filterKernel,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_5x5; y <= ROWS_HALF_5x5; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_5x5; x <= COLS_HALF_5x5; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_5x5) * COLS_5x5 + x + COLS_HALF_5x5;
            sum += color * filterKernel[idx];
        }
    }

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
kernel void filter_single_5x5(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              constant float* filterKernel,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_5x5(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_7x7):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_7x7(read_only image2d_t imgIn,
                            constant float* filterKernel,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_7x7; y <= ROWS_HALF_7x7; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_7x7; x <= COLS_HALF_7x7; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_7x7) * COLS_7x7 + x + COLS_HALF_7x7;
            sum += color * filterKernel[idx];
        }
    }

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
kernel void filter_single_7x7(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              constant float* filterKernel,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_7x7(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_9x9):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_9x9(read_only image2d_t imgIn,
                            constant float* filterKernel,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_9x9; y <= ROWS_HALF_9x9; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_9x9; x <= COLS_HALF_9x9; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_9x9) * COLS_9x9 + x + COLS_HALF_9x9;
            sum += color * filterKernel[idx];
        }
    }

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
kernel void filter_single_9x9(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              constant float* filterKernel,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_9x9(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

// Separation filter
/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_1x3):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_1x3(read_only image2d_t imgIn,
                            constant float* filterKernel,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_1x3; y <= ROWS_HALF_1x3; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_1x3; x <= COLS_HALF_1x3; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_1x3) * COLS_1x3 + x + COLS_HALF_1x3;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_1x3(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              constant float* filterKernel,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_1x3(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_1x5):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_1x5(read_only image2d_t imgIn,
                            constant float* filterKernel,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_1x5; y <= ROWS_HALF_1x5; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_1x5; x <= COLS_HALF_1x5; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_1x5) * COLS_1x5 + x + COLS_HALF_1x5;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_1x5(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              constant float* filterKernel,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_1x5(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_1x7):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_1x7(read_only image2d_t imgIn,
                            constant float* filterKernel,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_1x7; y <= ROWS_HALF_1x7; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_1x7; x <= COLS_HALF_1x7; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_1x7) * COLS_1x7 + x + COLS_HALF_1x7;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_1x7(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              constant float* filterKernel,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_1x7(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_1x9):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_1x9(read_only image2d_t imgIn,
                            constant float* filterKernel,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_1x9; y <= ROWS_HALF_1x9; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_1x9; x <= COLS_HALF_1x9; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_1x9) * COLS_1x9 + x + COLS_HALF_1x9;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_1x9(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              constant float* filterKernel,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_1x9(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_3x1):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_3x1(read_only image2d_t imgIn,
                            constant float* filterKernel,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_3x1; y <= ROWS_HALF_3x1; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_3x1; x <= COLS_HALF_3x1; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_3x1) * COLS_3x1 + x + COLS_HALF_3x1;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_3x1(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              constant float* filterKernel,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_3x1(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_5x1):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_5x1(read_only image2d_t imgIn,
                            constant float* filterKernel,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_5x1; y <= ROWS_HALF_5x1; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_5x1; x <= COLS_HALF_5x1; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_5x1) * COLS_5x1 + x + COLS_HALF_5x1;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_5x1(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              constant float* filterKernel,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_5x1(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_7x1):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_7x1(read_only image2d_t imgIn,
                            constant float* filterKernel,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_7x1; y <= ROWS_HALF_7x1; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_7x1; x <= COLS_HALF_7x1; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_7x1) * COLS_7x1 + x + COLS_HALF_7x1;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_7x1(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              constant float* filterKernel,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_7x1(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_9x1):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_9x1(read_only image2d_t imgIn,
                            constant float* filterKernel,
                            const int2 coordBase,
                            const int border)
{
    type_single sum = (type_single)(0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_9x1; y <= ROWS_HALF_9x1; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_9x1; x <= COLS_HALF_9x1; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_9x1) * COLS_9x1 + x + COLS_HALF_9x1;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_9x1(read_only image2d_t imgIn,
                              write_only image2d_t imgOut,
                              constant float* filterKernel,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_9x1(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}
/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double(read_only image2d_t imgIn,
                            constant float* filterKernel1,
                            constant float* filterKernel2,
                            const int filterRowsHalf,
                            const int filterCols,
                            const int filterColsHalf,
                            const int2 coordBase,
                            const int border)
{
    type_double sum = (type_double)(0.0f, 0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -filterRowsHalf; y <= filterRowsHalf; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -filterColsHalf; x <= filterColsHalf; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + filterRowsHalf) * filterCols + x + filterColsHalf;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a double filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2)
 * @param filterCols cols of the filter
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2)
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double(read_only image2d_t imgIn,
                              write_only image2d_t imgOut1,
                              write_only image2d_t imgOut2,
                              constant float* filterKernel1,
                              constant float* filterKernel2,
                              const int filterRowsHalf,
                              const int filterCols,
                              const int filterColsHalf,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double(imgIn, filterKernel1, filterKernel2, filterRowsHalf, filterCols, filterColsHalf, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

// Normal filter
/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_3x3):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_3x3(read_only image2d_t imgIn,
                            constant float* filterKernel1,
                            constant float* filterKernel2,
                            const int2 coordBase,
                            const int border)
{
    type_double sum = (type_double)(0.0f, 0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_3x3; y <= ROWS_HALF_3x3; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_3x3; x <= COLS_HALF_3x3; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_3x3) * COLS_3x3 + x + COLS_HALF_3x3;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

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
kernel void filter_double_3x3(read_only image2d_t imgIn,
                              write_only image2d_t imgOut1,
                              write_only image2d_t imgOut2,
                              constant float* filterKernel1,
                              constant float* filterKernel2,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_3x3(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_5x5):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_5x5(read_only image2d_t imgIn,
                            constant float* filterKernel1,
                            constant float* filterKernel2,
                            const int2 coordBase,
                            const int border)
{
    type_double sum = (type_double)(0.0f, 0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_5x5; y <= ROWS_HALF_5x5; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_5x5; x <= COLS_HALF_5x5; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_5x5) * COLS_5x5 + x + COLS_HALF_5x5;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

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
kernel void filter_double_5x5(read_only image2d_t imgIn,
                              write_only image2d_t imgOut1,
                              write_only image2d_t imgOut2,
                              constant float* filterKernel1,
                              constant float* filterKernel2,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_5x5(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_7x7):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_7x7(read_only image2d_t imgIn,
                            constant float* filterKernel1,
                            constant float* filterKernel2,
                            const int2 coordBase,
                            const int border)
{
    type_double sum = (type_double)(0.0f, 0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_7x7; y <= ROWS_HALF_7x7; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_7x7; x <= COLS_HALF_7x7; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_7x7) * COLS_7x7 + x + COLS_HALF_7x7;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

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
kernel void filter_double_7x7(read_only image2d_t imgIn,
                              write_only image2d_t imgOut1,
                              write_only image2d_t imgOut2,
                              constant float* filterKernel1,
                              constant float* filterKernel2,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_7x7(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_9x9):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_9x9(read_only image2d_t imgIn,
                            constant float* filterKernel1,
                            constant float* filterKernel2,
                            const int2 coordBase,
                            const int border)
{
    type_double sum = (type_double)(0.0f, 0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_9x9; y <= ROWS_HALF_9x9; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_9x9; x <= COLS_HALF_9x9; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_9x9) * COLS_9x9 + x + COLS_HALF_9x9;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

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
kernel void filter_double_9x9(read_only image2d_t imgIn,
                              write_only image2d_t imgOut1,
                              write_only image2d_t imgOut2,
                              constant float* filterKernel1,
                              constant float* filterKernel2,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_9x9(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

// Separation filter
/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_1x3):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_1x3(read_only image2d_t imgIn,
                            constant float* filterKernel1,
                            constant float* filterKernel2,
                            const int2 coordBase,
                            const int border)
{
    type_double sum = (type_double)(0.0f, 0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_1x3; y <= ROWS_HALF_1x3; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_1x3; x <= COLS_HALF_1x3; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_1x3) * COLS_1x3 + x + COLS_HALF_1x3;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a double filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_1x3(read_only image2d_t imgIn,
                              write_only image2d_t imgOut1,
                              write_only image2d_t imgOut2,
                              constant float* filterKernel1,
                              constant float* filterKernel2,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_1x3(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_1x5):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_1x5(read_only image2d_t imgIn,
                            constant float* filterKernel1,
                            constant float* filterKernel2,
                            const int2 coordBase,
                            const int border)
{
    type_double sum = (type_double)(0.0f, 0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_1x5; y <= ROWS_HALF_1x5; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_1x5; x <= COLS_HALF_1x5; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_1x5) * COLS_1x5 + x + COLS_HALF_1x5;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a double filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_1x5(read_only image2d_t imgIn,
                              write_only image2d_t imgOut1,
                              write_only image2d_t imgOut2,
                              constant float* filterKernel1,
                              constant float* filterKernel2,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_1x5(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_1x7):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_1x7(read_only image2d_t imgIn,
                            constant float* filterKernel1,
                            constant float* filterKernel2,
                            const int2 coordBase,
                            const int border)
{
    type_double sum = (type_double)(0.0f, 0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_1x7; y <= ROWS_HALF_1x7; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_1x7; x <= COLS_HALF_1x7; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_1x7) * COLS_1x7 + x + COLS_HALF_1x7;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a double filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_1x7(read_only image2d_t imgIn,
                              write_only image2d_t imgOut1,
                              write_only image2d_t imgOut2,
                              constant float* filterKernel1,
                              constant float* filterKernel2,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_1x7(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_1x9):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_1x9(read_only image2d_t imgIn,
                            constant float* filterKernel1,
                            constant float* filterKernel2,
                            const int2 coordBase,
                            const int border)
{
    type_double sum = (type_double)(0.0f, 0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_1x9; y <= ROWS_HALF_1x9; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_1x9; x <= COLS_HALF_1x9; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_1x9) * COLS_1x9 + x + COLS_HALF_1x9;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a double filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_1x9(read_only image2d_t imgIn,
                              write_only image2d_t imgOut1,
                              write_only image2d_t imgOut2,
                              constant float* filterKernel1,
                              constant float* filterKernel2,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_1x9(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_3x1):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_3x1(read_only image2d_t imgIn,
                            constant float* filterKernel1,
                            constant float* filterKernel2,
                            const int2 coordBase,
                            const int border)
{
    type_double sum = (type_double)(0.0f, 0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_3x1; y <= ROWS_HALF_3x1; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_3x1; x <= COLS_HALF_3x1; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_3x1) * COLS_3x1 + x + COLS_HALF_3x1;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a double filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_3x1(read_only image2d_t imgIn,
                              write_only image2d_t imgOut1,
                              write_only image2d_t imgOut2,
                              constant float* filterKernel1,
                              constant float* filterKernel2,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_3x1(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_5x1):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_5x1(read_only image2d_t imgIn,
                            constant float* filterKernel1,
                            constant float* filterKernel2,
                            const int2 coordBase,
                            const int border)
{
    type_double sum = (type_double)(0.0f, 0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_5x1; y <= ROWS_HALF_5x1; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_5x1; x <= COLS_HALF_5x1; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_5x1) * COLS_5x1 + x + COLS_HALF_5x1;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a double filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_5x1(read_only image2d_t imgIn,
                              write_only image2d_t imgOut1,
                              write_only image2d_t imgOut2,
                              constant float* filterKernel1,
                              constant float* filterKernel2,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_5x1(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_7x1):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_7x1(read_only image2d_t imgIn,
                            constant float* filterKernel1,
                            constant float* filterKernel2,
                            const int2 coordBase,
                            const int border)
{
    type_double sum = (type_double)(0.0f, 0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_7x1; y <= ROWS_HALF_7x1; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_7x1; x <= COLS_HALF_7x1; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_7x1) * COLS_7x1 + x + COLS_HALF_7x1;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a double filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_7x1(read_only image2d_t imgIn,
                              write_only image2d_t imgOut1,
                              write_only image2d_t imgOut2,
                              constant float* filterKernel1,
                              constant float* filterKernel2,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_7x1(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_9x1):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_9x1(read_only image2d_t imgIn,
                            constant float* filterKernel1,
                            constant float* filterKernel2,
                            const int2 coordBase,
                            const int border)
{
    type_double sum = (type_double)(0.0f, 0.0f);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int2 coordCurrent;
    int2 coordBorder;
    float color;

    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    #pragma unroll
    for (int y = -ROWS_HALF_9x1; y <= ROWS_HALF_9x1; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_9x1; x <= COLS_HALF_9x1; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_9x1) * COLS_9x1 + x + COLS_HALF_9x1;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a double filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_9x1(read_only image2d_t imgIn,
                              write_only image2d_t imgOut1,
                              write_only image2d_t imgOut2,
                              constant float* filterKernel1,
                              constant float* filterKernel2,
                              const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_9x1(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}
