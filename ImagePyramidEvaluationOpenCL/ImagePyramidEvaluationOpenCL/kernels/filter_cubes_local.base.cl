/**
 * Calculates the filter sum using local memory at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_MULTIPLICITY_local_DERIV_NxN):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
/* GENERATE_TYPE */ filter_sum_MULTIPLICITY_local_DERIV_NxN(read_only image2d_array_t imgIn/* GENERATE_REMOVE_PREDEFINED:,
                                   constant float* filterKernel/* GENERATE_DOUBLE:1,
                                   constant float* filterKernel2*/*/,
                                   const int filterRowsHalf, // GENERATE_REMOVE
                                   const int filterCols,     // GENERATE_REMOVE
                                   const int filterColsHalf, // GENERATE_REMOVE
                                   int4 coordBase,
                                   const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    // The exact size must be known at compile time (no dynamic memory allocation possible)
    // Adjust according to the highest needed filter size or set via compile parameter
    local float localBuffer[LOCAL_SIZE_COLS_NxN * LOCAL_SIZE_ROWS_NxN];   // Allocate local buffer

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    // The top left pixel in the current patch is the base for every work-item in the work-group
    int xBase = coordBase.x - xLocalId;
    int yBase = coordBase.y - yLocalId;

#if COLS_NxN >= 9 || ROWS_NxN >= 9
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
    for (int y = yLocalId; y < yLocalSize + 2 * ROWS_HALF_NxN; y += yLocalSize)
    {
        for (int x = xLocalId; x < xLocalSize + 2 * COLS_HALF_NxN; x += xLocalSize)
        {
            // Coordinate from the image patch which must be stored in the current local buffer position
            int4 coordBorder = borderCoordinate((int4)(x - COLS_HALF_NxN + xBase, y - ROWS_HALF_NxN + yBase, coordBase.z, 0), rows, cols, border);
            localBuffer[y * LOCAL_SIZE_COLS_NxN + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
        }
    }
#else
    /*
     * Copy the image patch including the padding from global to local memory. The local ID is mapped to the 1D index and this index is remapped to the size of the local buffer. It only needs 2 iterations
     *
     * More index calculations but less memory accesses, better for smaller filter sizes (a 9x9 filter is the first which needs 3 iterations)
     */
    for (int idx1D = yLocalId * xLocalSize + xLocalId; idx1D < (LOCAL_SIZE_COLS_NxN * LOCAL_SIZE_ROWS_NxN); idx1D += xLocalSize * yLocalSize) {
        int x = idx1D % LOCAL_SIZE_COLS_NxN;
        int y = idx1D / LOCAL_SIZE_COLS_NxN;
        
        // Coordinate from the image patch which must be stored in the current local buffer position
        int4 coordBorder = borderCoordinate((int4)(x - COLS_HALF_NxN + xBase, y - ROWS_HALF_NxN + yBase, coordBase.z, 0), rows, cols, border);
        localBuffer[y * LOCAL_SIZE_COLS_NxN + x] = read_imagef(imgIn, sampler, coordBorder).x;   // Fill local buffer
    }
#endif
        
    // Wait until the image patch is loaded in local memory
    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    // The local buffer includes the padding but the relevant area is only the inner part
    // Note that the local buffer contains all pixels which are read but only the inner part contains pixels where an output value is written
    coordBase = (int4)(xLocalId + COLS_HALF_NxN, yLocalId + ROWS_HALF_NxN, 0, 0);
    int2 coordCurrent;
    float color;
    /* GENERATE_TYPE */ sum = (/* GENERATE_TYPE */)(0.0f/* GENERATE_DOUBLE:, 0.0f*/);
    
    // GENERATE_KERNEL_BEGIN
    // Image patch is row-wise accessed
    #pragma unroll
    for (int y = -ROWS_HALF_NxN; y <= ROWS_HALF_NxN; ++y)
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_NxN; x <= COLS_HALF_NxN; ++x)
        {
            coordCurrent.x = coordBase.x + x;
            color = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_NxN + coordCurrent.x];    // Read from local buffer

            const int idx = (y + ROWS_HALF_NxN) * COLS_NxN + x + COLS_HALF_NxN;
            sum/* GENERATE_DOUBLE:.x*/ += color * filterKernel/* GENERATE_DOUBLE:1*/[idx];
            /* GENERATE_DOUBLE:sum.y += color * filterKernel2[idx];*/
        }
    }
    // GENERATE_KERNEL_END
    
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
kernel void filter_MULTIPLICITY_local_DERIV_NxN(read_only image2d_array_t imgIn,
                                    write_only image2d_array_t imgOut/* GENERATE_DOUBLE:1,
                                    write_only image2d_array_t imgOut2*//* GENERATE_REMOVE_PREDEFINED:,
                                    constant float* filterKernel/* GENERATE_DOUBLE:1,
                                    constant float* filterKernel2*/*/,
                                    const int filterRowsHalf, // GENERATE_REMOVE
                                    const int filterCols,     // GENERATE_REMOVE
                                    const int filterColsHalf, // GENERATE_REMOVE
                                    const int border)
{
    int4 coordBase = (int4)(get_global_id(0), get_global_id(1), get_global_id(2), 0);

    /* GENERATE_TYPE */ sum = filter_sum_MULTIPLICITY_local_DERIV_NxN(imgIn/* GENERATE_REMOVE_PREDEFINED:, filterKernel/* GENERATE_DOUBLE:1, filterKernel2*/*/,/* GENERATE_REMOVE: filterRowsHalf, filterCols, filterColsHalf,*/ coordBase, border);

    write_imagef(imgOut/* GENERATE_DOUBLE:1*/, coordBase, sum/* GENERATE_DOUBLE:.x*/);
    /* GENERATE_DOUBLE:write_imagef(imgOut2, coordBase, sum.y);*/
}
