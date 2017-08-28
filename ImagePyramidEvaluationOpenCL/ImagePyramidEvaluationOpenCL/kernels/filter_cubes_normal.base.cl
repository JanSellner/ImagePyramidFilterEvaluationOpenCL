/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_MULTIPLICITY_DERIV_NxN):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
/* GENERATE_TYPE */ filter_sum_MULTIPLICITY_DERIV_NxN(read_only image2d_array_t imgIn/* GENERATE_REMOVE_PREDEFINED:,
                            constant float* filterKernel/* GENERATE_DOUBLE:1,
                            constant float* filterKernel2*/*/,
                            const int filterRowsHalf,   // GENERATE_REMOVE
                            const int filterCols,       // GENERATE_REMOVE
                            const int filterColsHalf,   // GENERATE_REMOVE
                            const int4 coordBase,
                            const int border)
{
    /* GENERATE_TYPE */ sum = (/* GENERATE_TYPE */)(0.0f/* GENERATE_DOUBLE:, 0.0f*/);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);
    int4 coordCurrent;
    int4 coordBorder;
    float color;
    
    // GENERATE_KERNEL_BEGIN
    // Image patch is row-wise accessed
    // Filter kernel is centred in the middle
    coordCurrent.z = coordBase.z;
    #pragma unroll
    for (int y = -ROWS_HALF_NxN; y <= ROWS_HALF_NxN; ++y)       // Start at the top left corner of the filter
    {
        coordCurrent.y = coordBase.y + y;
        #pragma unroll
        for (int x = -COLS_HALF_NxN; x <= COLS_HALF_NxN; ++x)   // And end at the bottom right corner
        {
            coordCurrent.x = coordBase.x + x;
            coordBorder = borderCoordinate(coordCurrent, rows, cols, border);
            color = read_imagef(imgIn, sampler, coordBorder).x;

            const int idx = (y + ROWS_HALF_NxN) * COLS_NxN + x + COLS_HALF_NxN;
            sum/* GENERATE_DOUBLE:.x*/ += color * filterKernel/* GENERATE_DOUBLE:1*/[idx];
            /* GENERATE_DOUBLE:sum.y += color * filterKernel2[idx];*/
        }
    }
    // GENERATE_KERNEL_END

    return sum;
}

/**
 * Filter kernel for a MULTIPLICITY filter supposed to be called from the host.
 * 
 * @param imgIn input image
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_MULTIPLICITY_DERIV_NxN(read_only image2d_array_t imgIn,
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

    /* GENERATE_TYPE */ sum = filter_sum_MULTIPLICITY_DERIV_NxN(imgIn/* GENERATE_REMOVE_PREDEFINED:, filterKernel/* GENERATE_DOUBLE:1, filterKernel2*/*/,/* GENERATE_REMOVE: filterRowsHalf, filterCols, filterColsHalf,*/ coordBase, border);

    write_imagef(imgOut/* GENERATE_DOUBLE:1*/, coordBase, sum/* GENERATE_DOUBLE:.x*/);
    /* GENERATE_DOUBLE:write_imagef(imgOut2, coordBase, sum.y);*/
}
