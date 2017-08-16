/* This file is generated. Do not modify. */

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_local):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_local(read_only image2d_t imgIn,
                                   constant float* filterKernel,
                                   const int filterRowsHalf,
                                   const int filterCols,
                                   const int filterColsHalf,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_21x21 * LOCAL_SIZE_ROWS_21x21];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if filterCols >= 9 || filterRows >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * filterRowsHalf; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * filterColsHalf; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - filterColsHalf + xBase, y - filterRowsHalf + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_21x21 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_21x21 * LOCAL_SIZE_ROWS_21x21); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_21x21;
        int y = idx1D / LOCAL_SIZE_COLS_21x21;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - filterColsHalf + xBase, y - filterRowsHalf + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_21x21 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + filterColsHalf, yLocalId + filterRowsHalf);
    int2 coordCurrent;
    float color;
    type_single sum = (type_single)(0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -filterRowsHalf; y <= filterRowsHalf; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -filterColsHalf; x <= filterColsHalf; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_21x21 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + filterRowsHalf) * filterCols + x + filterColsHalf;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2)
 * @param filterCols cols of the filter
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2)
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_local(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut,
                                    constant float* filterKernel,
                                    const int filterRowsHalf,
                                    const int filterCols,
                                    const int filterColsHalf,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_local(imgIn, filterKernel, filterRowsHalf, filterCols, filterColsHalf, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

// Normal filter
/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_local_3x3):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_local_3x3(read_only image2d_t imgIn,
                                   constant float* filterKernel,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_3x3 * LOCAL_SIZE_ROWS_3x3];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_3x3 >= 9 || ROWS_3x3 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_3x3; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_3x3; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_3x3 + xBase, y - ROWS_HALF_3x3 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_3x3 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_3x3 * LOCAL_SIZE_ROWS_3x3); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_3x3;
        int y = idx1D / LOCAL_SIZE_COLS_3x3;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_3x3 + xBase, y - ROWS_HALF_3x3 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_3x3 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_3x3, yLocalId + ROWS_HALF_3x3);
    int2 coordCurrent;
    float color;
    type_single sum = (type_single)(0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_3x3; y <= ROWS_HALF_3x3; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_3x3; x <= COLS_HALF_3x3; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_3x3 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_3x3) * COLS_3x3 + x + COLS_HALF_3x3;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_local_3x3(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut,
                                    constant float* filterKernel,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_local_3x3(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_local_5x5):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_local_5x5(read_only image2d_t imgIn,
                                   constant float* filterKernel,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_5x5 * LOCAL_SIZE_ROWS_5x5];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_5x5 >= 9 || ROWS_5x5 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_5x5; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_5x5; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_5x5 + xBase, y - ROWS_HALF_5x5 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_5x5 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_5x5 * LOCAL_SIZE_ROWS_5x5); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_5x5;
        int y = idx1D / LOCAL_SIZE_COLS_5x5;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_5x5 + xBase, y - ROWS_HALF_5x5 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_5x5 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_5x5, yLocalId + ROWS_HALF_5x5);
    int2 coordCurrent;
    float color;
    type_single sum = (type_single)(0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_5x5; y <= ROWS_HALF_5x5; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_5x5; x <= COLS_HALF_5x5; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_5x5 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_5x5) * COLS_5x5 + x + COLS_HALF_5x5;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_local_5x5(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut,
                                    constant float* filterKernel,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_local_5x5(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_local_7x7):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_local_7x7(read_only image2d_t imgIn,
                                   constant float* filterKernel,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_7x7 * LOCAL_SIZE_ROWS_7x7];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_7x7 >= 9 || ROWS_7x7 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_7x7; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_7x7; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_7x7 + xBase, y - ROWS_HALF_7x7 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_7x7 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_7x7 * LOCAL_SIZE_ROWS_7x7); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_7x7;
        int y = idx1D / LOCAL_SIZE_COLS_7x7;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_7x7 + xBase, y - ROWS_HALF_7x7 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_7x7 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_7x7, yLocalId + ROWS_HALF_7x7);
    int2 coordCurrent;
    float color;
    type_single sum = (type_single)(0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_7x7; y <= ROWS_HALF_7x7; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_7x7; x <= COLS_HALF_7x7; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_7x7 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_7x7) * COLS_7x7 + x + COLS_HALF_7x7;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_local_7x7(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut,
                                    constant float* filterKernel,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_local_7x7(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_local_9x9):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_local_9x9(read_only image2d_t imgIn,
                                   constant float* filterKernel,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_9x9 * LOCAL_SIZE_ROWS_9x9];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_9x9 >= 9 || ROWS_9x9 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_9x9; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_9x9; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_9x9 + xBase, y - ROWS_HALF_9x9 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_9x9 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_9x9 * LOCAL_SIZE_ROWS_9x9); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_9x9;
        int y = idx1D / LOCAL_SIZE_COLS_9x9;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_9x9 + xBase, y - ROWS_HALF_9x9 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_9x9 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_9x9, yLocalId + ROWS_HALF_9x9);
    int2 coordCurrent;
    float color;
    type_single sum = (type_single)(0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_9x9; y <= ROWS_HALF_9x9; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_9x9; x <= COLS_HALF_9x9; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_9x9 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_9x9) * COLS_9x9 + x + COLS_HALF_9x9;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_local_9x9(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut,
                                    constant float* filterKernel,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_local_9x9(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

// Separation filter
/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_local_1x3):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_local_1x3(read_only image2d_t imgIn,
                                   constant float* filterKernel,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_1x3 * LOCAL_SIZE_ROWS_1x3];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_1x3 >= 9 || ROWS_1x3 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_1x3; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_1x3; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_1x3 + xBase, y - ROWS_HALF_1x3 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_1x3 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_1x3 * LOCAL_SIZE_ROWS_1x3); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_1x3;
        int y = idx1D / LOCAL_SIZE_COLS_1x3;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_1x3 + xBase, y - ROWS_HALF_1x3 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_1x3 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_1x3, yLocalId + ROWS_HALF_1x3);
    int2 coordCurrent;
    float color;
    type_single sum = (type_single)(0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_1x3; y <= ROWS_HALF_1x3; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_1x3; x <= COLS_HALF_1x3; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_1x3 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_1x3) * COLS_1x3 + x + COLS_HALF_1x3;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_local_1x3(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut,
                                    constant float* filterKernel,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_local_1x3(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_local_1x5):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_local_1x5(read_only image2d_t imgIn,
                                   constant float* filterKernel,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_1x5 * LOCAL_SIZE_ROWS_1x5];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_1x5 >= 9 || ROWS_1x5 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_1x5; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_1x5; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_1x5 + xBase, y - ROWS_HALF_1x5 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_1x5 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_1x5 * LOCAL_SIZE_ROWS_1x5); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_1x5;
        int y = idx1D / LOCAL_SIZE_COLS_1x5;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_1x5 + xBase, y - ROWS_HALF_1x5 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_1x5 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_1x5, yLocalId + ROWS_HALF_1x5);
    int2 coordCurrent;
    float color;
    type_single sum = (type_single)(0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_1x5; y <= ROWS_HALF_1x5; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_1x5; x <= COLS_HALF_1x5; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_1x5 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_1x5) * COLS_1x5 + x + COLS_HALF_1x5;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_local_1x5(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut,
                                    constant float* filterKernel,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_local_1x5(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_local_1x7):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_local_1x7(read_only image2d_t imgIn,
                                   constant float* filterKernel,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_1x7 * LOCAL_SIZE_ROWS_1x7];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_1x7 >= 9 || ROWS_1x7 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_1x7; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_1x7; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_1x7 + xBase, y - ROWS_HALF_1x7 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_1x7 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_1x7 * LOCAL_SIZE_ROWS_1x7); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_1x7;
        int y = idx1D / LOCAL_SIZE_COLS_1x7;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_1x7 + xBase, y - ROWS_HALF_1x7 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_1x7 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_1x7, yLocalId + ROWS_HALF_1x7);
    int2 coordCurrent;
    float color;
    type_single sum = (type_single)(0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_1x7; y <= ROWS_HALF_1x7; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_1x7; x <= COLS_HALF_1x7; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_1x7 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_1x7) * COLS_1x7 + x + COLS_HALF_1x7;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_local_1x7(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut,
                                    constant float* filterKernel,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_local_1x7(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_local_1x9):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_local_1x9(read_only image2d_t imgIn,
                                   constant float* filterKernel,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_1x9 * LOCAL_SIZE_ROWS_1x9];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_1x9 >= 9 || ROWS_1x9 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_1x9; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_1x9; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_1x9 + xBase, y - ROWS_HALF_1x9 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_1x9 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_1x9 * LOCAL_SIZE_ROWS_1x9); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_1x9;
        int y = idx1D / LOCAL_SIZE_COLS_1x9;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_1x9 + xBase, y - ROWS_HALF_1x9 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_1x9 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_1x9, yLocalId + ROWS_HALF_1x9);
    int2 coordCurrent;
    float color;
    type_single sum = (type_single)(0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_1x9; y <= ROWS_HALF_1x9; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_1x9; x <= COLS_HALF_1x9; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_1x9 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_1x9) * COLS_1x9 + x + COLS_HALF_1x9;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_local_1x9(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut,
                                    constant float* filterKernel,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_local_1x9(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_local_3x1):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_local_3x1(read_only image2d_t imgIn,
                                   constant float* filterKernel,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_3x1 * LOCAL_SIZE_ROWS_3x1];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_3x1 >= 9 || ROWS_3x1 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_3x1; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_3x1; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_3x1 + xBase, y - ROWS_HALF_3x1 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_3x1 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_3x1 * LOCAL_SIZE_ROWS_3x1); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_3x1;
        int y = idx1D / LOCAL_SIZE_COLS_3x1;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_3x1 + xBase, y - ROWS_HALF_3x1 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_3x1 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_3x1, yLocalId + ROWS_HALF_3x1);
    int2 coordCurrent;
    float color;
    type_single sum = (type_single)(0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_3x1; y <= ROWS_HALF_3x1; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_3x1; x <= COLS_HALF_3x1; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_3x1 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_3x1) * COLS_3x1 + x + COLS_HALF_3x1;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_local_3x1(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut,
                                    constant float* filterKernel,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_local_3x1(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_local_5x1):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_local_5x1(read_only image2d_t imgIn,
                                   constant float* filterKernel,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_5x1 * LOCAL_SIZE_ROWS_5x1];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_5x1 >= 9 || ROWS_5x1 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_5x1; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_5x1; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_5x1 + xBase, y - ROWS_HALF_5x1 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_5x1 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_5x1 * LOCAL_SIZE_ROWS_5x1); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_5x1;
        int y = idx1D / LOCAL_SIZE_COLS_5x1;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_5x1 + xBase, y - ROWS_HALF_5x1 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_5x1 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_5x1, yLocalId + ROWS_HALF_5x1);
    int2 coordCurrent;
    float color;
    type_single sum = (type_single)(0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_5x1; y <= ROWS_HALF_5x1; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_5x1; x <= COLS_HALF_5x1; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_5x1 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_5x1) * COLS_5x1 + x + COLS_HALF_5x1;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_local_5x1(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut,
                                    constant float* filterKernel,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_local_5x1(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_local_7x1):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_local_7x1(read_only image2d_t imgIn,
                                   constant float* filterKernel,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_7x1 * LOCAL_SIZE_ROWS_7x1];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_7x1 >= 9 || ROWS_7x1 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_7x1; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_7x1; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_7x1 + xBase, y - ROWS_HALF_7x1 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_7x1 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_7x1 * LOCAL_SIZE_ROWS_7x1); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_7x1;
        int y = idx1D / LOCAL_SIZE_COLS_7x1;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_7x1 + xBase, y - ROWS_HALF_7x1 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_7x1 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_7x1, yLocalId + ROWS_HALF_7x1);
    int2 coordCurrent;
    float color;
    type_single sum = (type_single)(0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_7x1; y <= ROWS_HALF_7x1; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_7x1; x <= COLS_HALF_7x1; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_7x1 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_7x1) * COLS_7x1 + x + COLS_HALF_7x1;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_local_7x1(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut,
                                    constant float* filterKernel,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_local_7x1(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_single_local_9x1):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_single filter_sum_single_local_9x1(read_only image2d_t imgIn,
                                   constant float* filterKernel,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_9x1 * LOCAL_SIZE_ROWS_9x1];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_9x1 >= 9 || ROWS_9x1 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_9x1; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_9x1; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_9x1 + xBase, y - ROWS_HALF_9x1 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_9x1 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_9x1 * LOCAL_SIZE_ROWS_9x1); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_9x1;
        int y = idx1D / LOCAL_SIZE_COLS_9x1;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_9x1 + xBase, y - ROWS_HALF_9x1 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_9x1 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_9x1, yLocalId + ROWS_HALF_9x1);
    int2 coordCurrent;
    float color;
    type_single sum = (type_single)(0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_9x1; y <= ROWS_HALF_9x1; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_9x1; x <= COLS_HALF_9x1; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_9x1 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_9x1) * COLS_9x1 + x + COLS_HALF_9x1;
            sum += color * filterKernel[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_single_local_9x1(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut,
                                    constant float* filterKernel,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_single sum = filter_sum_single_local_9x1(imgIn, filterKernel, coordBase, border);

    write_imagef(imgOut, coordBase, sum);
}
/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_local):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_local(read_only image2d_t imgIn,
                                   constant float* filterKernel1,
                                   constant float* filterKernel2,
                                   const int filterRowsHalf,
                                   const int filterCols,
                                   const int filterColsHalf,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_21x21 * LOCAL_SIZE_ROWS_21x21];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if filterCols >= 9 || filterRows >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * filterRowsHalf; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * filterColsHalf; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - filterColsHalf + xBase, y - filterRowsHalf + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_21x21 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_21x21 * LOCAL_SIZE_ROWS_21x21); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_21x21;
        int y = idx1D / LOCAL_SIZE_COLS_21x21;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - filterColsHalf + xBase, y - filterRowsHalf + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_21x21 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + filterColsHalf, yLocalId + filterRowsHalf);
    int2 coordCurrent;
    float color;
    type_double sum = (type_double)(0.0f, 0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -filterRowsHalf; y <= filterRowsHalf; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -filterColsHalf; x <= filterColsHalf; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_21x21 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + filterRowsHalf) * filterCols + x + filterColsHalf;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2)
 * @param filterCols cols of the filter
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2)
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_local(read_only image2d_t imgIn,
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

    type_double sum = filter_sum_double_local(imgIn, filterKernel1, filterKernel2, filterRowsHalf, filterCols, filterColsHalf, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

// Normal filter
/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_local_3x3):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_local_3x3(read_only image2d_t imgIn,
                                   constant float* filterKernel1,
                                   constant float* filterKernel2,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_3x3 * LOCAL_SIZE_ROWS_3x3];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_3x3 >= 9 || ROWS_3x3 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_3x3; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_3x3; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_3x3 + xBase, y - ROWS_HALF_3x3 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_3x3 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_3x3 * LOCAL_SIZE_ROWS_3x3); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_3x3;
        int y = idx1D / LOCAL_SIZE_COLS_3x3;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_3x3 + xBase, y - ROWS_HALF_3x3 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_3x3 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_3x3, yLocalId + ROWS_HALF_3x3);
    int2 coordCurrent;
    float color;
    type_double sum = (type_double)(0.0f, 0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_3x3; y <= ROWS_HALF_3x3; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_3x3; x <= COLS_HALF_3x3; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_3x3 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_3x3) * COLS_3x3 + x + COLS_HALF_3x3;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_local_3x3(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut1,
                                    write_only image2d_t imgOut2,
                                    constant float* filterKernel1,
                                    constant float* filterKernel2,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_local_3x3(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_local_5x5):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_local_5x5(read_only image2d_t imgIn,
                                   constant float* filterKernel1,
                                   constant float* filterKernel2,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_5x5 * LOCAL_SIZE_ROWS_5x5];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_5x5 >= 9 || ROWS_5x5 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_5x5; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_5x5; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_5x5 + xBase, y - ROWS_HALF_5x5 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_5x5 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_5x5 * LOCAL_SIZE_ROWS_5x5); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_5x5;
        int y = idx1D / LOCAL_SIZE_COLS_5x5;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_5x5 + xBase, y - ROWS_HALF_5x5 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_5x5 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_5x5, yLocalId + ROWS_HALF_5x5);
    int2 coordCurrent;
    float color;
    type_double sum = (type_double)(0.0f, 0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_5x5; y <= ROWS_HALF_5x5; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_5x5; x <= COLS_HALF_5x5; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_5x5 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_5x5) * COLS_5x5 + x + COLS_HALF_5x5;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_local_5x5(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut1,
                                    write_only image2d_t imgOut2,
                                    constant float* filterKernel1,
                                    constant float* filterKernel2,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_local_5x5(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_local_7x7):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_local_7x7(read_only image2d_t imgIn,
                                   constant float* filterKernel1,
                                   constant float* filterKernel2,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_7x7 * LOCAL_SIZE_ROWS_7x7];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_7x7 >= 9 || ROWS_7x7 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_7x7; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_7x7; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_7x7 + xBase, y - ROWS_HALF_7x7 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_7x7 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_7x7 * LOCAL_SIZE_ROWS_7x7); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_7x7;
        int y = idx1D / LOCAL_SIZE_COLS_7x7;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_7x7 + xBase, y - ROWS_HALF_7x7 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_7x7 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_7x7, yLocalId + ROWS_HALF_7x7);
    int2 coordCurrent;
    float color;
    type_double sum = (type_double)(0.0f, 0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_7x7; y <= ROWS_HALF_7x7; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_7x7; x <= COLS_HALF_7x7; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_7x7 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_7x7) * COLS_7x7 + x + COLS_HALF_7x7;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_local_7x7(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut1,
                                    write_only image2d_t imgOut2,
                                    constant float* filterKernel1,
                                    constant float* filterKernel2,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_local_7x7(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_local_9x9):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_local_9x9(read_only image2d_t imgIn,
                                   constant float* filterKernel1,
                                   constant float* filterKernel2,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_9x9 * LOCAL_SIZE_ROWS_9x9];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_9x9 >= 9 || ROWS_9x9 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_9x9; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_9x9; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_9x9 + xBase, y - ROWS_HALF_9x9 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_9x9 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_9x9 * LOCAL_SIZE_ROWS_9x9); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_9x9;
        int y = idx1D / LOCAL_SIZE_COLS_9x9;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_9x9 + xBase, y - ROWS_HALF_9x9 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_9x9 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_9x9, yLocalId + ROWS_HALF_9x9);
    int2 coordCurrent;
    float color;
    type_double sum = (type_double)(0.0f, 0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_9x9; y <= ROWS_HALF_9x9; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_9x9; x <= COLS_HALF_9x9; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_9x9 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_9x9) * COLS_9x9 + x + COLS_HALF_9x9;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_local_9x9(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut1,
                                    write_only image2d_t imgOut2,
                                    constant float* filterKernel1,
                                    constant float* filterKernel2,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_local_9x9(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

// Separation filter
/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_local_1x3):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_local_1x3(read_only image2d_t imgIn,
                                   constant float* filterKernel1,
                                   constant float* filterKernel2,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_1x3 * LOCAL_SIZE_ROWS_1x3];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_1x3 >= 9 || ROWS_1x3 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_1x3; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_1x3; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_1x3 + xBase, y - ROWS_HALF_1x3 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_1x3 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_1x3 * LOCAL_SIZE_ROWS_1x3); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_1x3;
        int y = idx1D / LOCAL_SIZE_COLS_1x3;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_1x3 + xBase, y - ROWS_HALF_1x3 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_1x3 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_1x3, yLocalId + ROWS_HALF_1x3);
    int2 coordCurrent;
    float color;
    type_double sum = (type_double)(0.0f, 0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_1x3; y <= ROWS_HALF_1x3; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_1x3; x <= COLS_HALF_1x3; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_1x3 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_1x3) * COLS_1x3 + x + COLS_HALF_1x3;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_local_1x3(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut1,
                                    write_only image2d_t imgOut2,
                                    constant float* filterKernel1,
                                    constant float* filterKernel2,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_local_1x3(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_local_1x5):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_local_1x5(read_only image2d_t imgIn,
                                   constant float* filterKernel1,
                                   constant float* filterKernel2,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_1x5 * LOCAL_SIZE_ROWS_1x5];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_1x5 >= 9 || ROWS_1x5 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_1x5; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_1x5; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_1x5 + xBase, y - ROWS_HALF_1x5 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_1x5 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_1x5 * LOCAL_SIZE_ROWS_1x5); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_1x5;
        int y = idx1D / LOCAL_SIZE_COLS_1x5;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_1x5 + xBase, y - ROWS_HALF_1x5 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_1x5 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_1x5, yLocalId + ROWS_HALF_1x5);
    int2 coordCurrent;
    float color;
    type_double sum = (type_double)(0.0f, 0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_1x5; y <= ROWS_HALF_1x5; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_1x5; x <= COLS_HALF_1x5; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_1x5 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_1x5) * COLS_1x5 + x + COLS_HALF_1x5;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_local_1x5(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut1,
                                    write_only image2d_t imgOut2,
                                    constant float* filterKernel1,
                                    constant float* filterKernel2,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_local_1x5(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_local_1x7):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_local_1x7(read_only image2d_t imgIn,
                                   constant float* filterKernel1,
                                   constant float* filterKernel2,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_1x7 * LOCAL_SIZE_ROWS_1x7];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_1x7 >= 9 || ROWS_1x7 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_1x7; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_1x7; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_1x7 + xBase, y - ROWS_HALF_1x7 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_1x7 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_1x7 * LOCAL_SIZE_ROWS_1x7); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_1x7;
        int y = idx1D / LOCAL_SIZE_COLS_1x7;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_1x7 + xBase, y - ROWS_HALF_1x7 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_1x7 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_1x7, yLocalId + ROWS_HALF_1x7);
    int2 coordCurrent;
    float color;
    type_double sum = (type_double)(0.0f, 0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_1x7; y <= ROWS_HALF_1x7; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_1x7; x <= COLS_HALF_1x7; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_1x7 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_1x7) * COLS_1x7 + x + COLS_HALF_1x7;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_local_1x7(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut1,
                                    write_only image2d_t imgOut2,
                                    constant float* filterKernel1,
                                    constant float* filterKernel2,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_local_1x7(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_local_1x9):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_local_1x9(read_only image2d_t imgIn,
                                   constant float* filterKernel1,
                                   constant float* filterKernel2,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_1x9 * LOCAL_SIZE_ROWS_1x9];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_1x9 >= 9 || ROWS_1x9 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_1x9; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_1x9; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_1x9 + xBase, y - ROWS_HALF_1x9 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_1x9 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_1x9 * LOCAL_SIZE_ROWS_1x9); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_1x9;
        int y = idx1D / LOCAL_SIZE_COLS_1x9;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_1x9 + xBase, y - ROWS_HALF_1x9 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_1x9 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_1x9, yLocalId + ROWS_HALF_1x9);
    int2 coordCurrent;
    float color;
    type_double sum = (type_double)(0.0f, 0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_1x9; y <= ROWS_HALF_1x9; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_1x9; x <= COLS_HALF_1x9; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_1x9 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_1x9) * COLS_1x9 + x + COLS_HALF_1x9;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_local_1x9(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut1,
                                    write_only image2d_t imgOut2,
                                    constant float* filterKernel1,
                                    constant float* filterKernel2,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_local_1x9(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_local_3x1):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_local_3x1(read_only image2d_t imgIn,
                                   constant float* filterKernel1,
                                   constant float* filterKernel2,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_3x1 * LOCAL_SIZE_ROWS_3x1];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_3x1 >= 9 || ROWS_3x1 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_3x1; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_3x1; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_3x1 + xBase, y - ROWS_HALF_3x1 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_3x1 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_3x1 * LOCAL_SIZE_ROWS_3x1); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_3x1;
        int y = idx1D / LOCAL_SIZE_COLS_3x1;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_3x1 + xBase, y - ROWS_HALF_3x1 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_3x1 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_3x1, yLocalId + ROWS_HALF_3x1);
    int2 coordCurrent;
    float color;
    type_double sum = (type_double)(0.0f, 0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_3x1; y <= ROWS_HALF_3x1; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_3x1; x <= COLS_HALF_3x1; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_3x1 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_3x1) * COLS_3x1 + x + COLS_HALF_3x1;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_local_3x1(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut1,
                                    write_only image2d_t imgOut2,
                                    constant float* filterKernel1,
                                    constant float* filterKernel2,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_local_3x1(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_local_5x1):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_local_5x1(read_only image2d_t imgIn,
                                   constant float* filterKernel1,
                                   constant float* filterKernel2,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_5x1 * LOCAL_SIZE_ROWS_5x1];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_5x1 >= 9 || ROWS_5x1 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_5x1; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_5x1; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_5x1 + xBase, y - ROWS_HALF_5x1 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_5x1 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_5x1 * LOCAL_SIZE_ROWS_5x1); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_5x1;
        int y = idx1D / LOCAL_SIZE_COLS_5x1;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_5x1 + xBase, y - ROWS_HALF_5x1 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_5x1 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_5x1, yLocalId + ROWS_HALF_5x1);
    int2 coordCurrent;
    float color;
    type_double sum = (type_double)(0.0f, 0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_5x1; y <= ROWS_HALF_5x1; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_5x1; x <= COLS_HALF_5x1; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_5x1 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_5x1) * COLS_5x1 + x + COLS_HALF_5x1;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_local_5x1(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut1,
                                    write_only image2d_t imgOut2,
                                    constant float* filterKernel1,
                                    constant float* filterKernel2,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_local_5x1(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_local_7x1):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_local_7x1(read_only image2d_t imgIn,
                                   constant float* filterKernel1,
                                   constant float* filterKernel2,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_7x1 * LOCAL_SIZE_ROWS_7x1];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_7x1 >= 9 || ROWS_7x1 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_7x1; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_7x1; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_7x1 + xBase, y - ROWS_HALF_7x1 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_7x1 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_7x1 * LOCAL_SIZE_ROWS_7x1); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_7x1;
        int y = idx1D / LOCAL_SIZE_COLS_7x1;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_7x1 + xBase, y - ROWS_HALF_7x1 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_7x1 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_7x1, yLocalId + ROWS_HALF_7x1);
    int2 coordCurrent;
    float color;
    type_double sum = (type_double)(0.0f, 0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_7x1; y <= ROWS_HALF_7x1; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_7x1; x <= COLS_HALF_7x1; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_7x1 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_7x1) * COLS_7x1 + x + COLS_HALF_7x1;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_local_7x1(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut1,
                                    write_only image2d_t imgOut2,
                                    constant float* filterKernel1,
                                    constant float* filterKernel2,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_local_7x1(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}

/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_double_local_9x1):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
type_double filter_sum_double_local_9x1(read_only image2d_t imgIn,
                                   constant float* filterKernel1,
                                   constant float* filterKernel2,
                                   int2 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_9x1 * LOCAL_SIZE_ROWS_9x1];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_9x1 >= 9 || ROWS_9x1 >= 9
    /*
     * Copy the image patch including the padding from global to local memory. Consider for example a 2x2 patch with a padding of 1 px:
     * bbbb
     * bxxb
     * bxxb
     * bbbb
     * The following pattern fills the local buffer in 4 iterations with a local work-group size of 2x2
     * 1122
     * 1122
     * 3344
     * 3344
     * The number denotes the iteration when the corresponding buffer element is filled. Note that the local buffer is filled beginning in the top left corner (of the buffer)
     *
     * Less index calculation but more memory accesses, better for larger filter sizes
     */
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_9x1; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_9x1; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_9x1 + xBase, y - ROWS_HALF_9x1 + yBase), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_9x1 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_9x1 * LOCAL_SIZE_ROWS_9x1); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_9x1;
        int y = idx1D / LOCAL_SIZE_COLS_9x1;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int2 coordBorder = borderCoordinate((int2)(x - COLS_HALF_9x1 + xBase, y - ROWS_HALF_9x1 + yBase), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_9x1 + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int2)(xLocalId + COLS_HALF_9x1, yLocalId + ROWS_HALF_9x1);
    int2 coordCurrent;
    float color;
    type_double sum = (type_double)(0.0f, 0.0f);

    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_9x1; y <= ROWS_HALF_9x1; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_9x1; x <= COLS_HALF_9x1; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_9x1 + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_9x1) * COLS_9x1 + x + COLS_HALF_9x1;
            sum.x += color * filterKernel1[idx];
            sum.y += color * filterKernel2[idx];
        }
    }

    return sum;
}

/**
 * Filter kernel for a single filter using local memory supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_double_local_9x1(read_only image2d_t imgIn,
                                    write_only image2d_t imgOut1,
                                    write_only image2d_t imgOut2,
                                    constant float* filterKernel1,
                                    constant float* filterKernel2,
                                    const int border)
{
    int2 coordBase = (int2)(get_global_id(0), get_global_id(1));

    type_double sum = filter_sum_double_local_9x1(imgIn, filterKernel1, filterKernel2, coordBase, border);

    write_imagef(imgOut1, coordBase, sum.x);
    write_imagef(imgOut2, coordBase, sum.y);
}
