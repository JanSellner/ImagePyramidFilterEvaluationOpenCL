/**
 * Calculates the filter sum at a specified pixel position. Supposed to be called from other kernels.
 * 
 * Additional parameters compared to the base function (filter_MULTIPLICITY_DERIV_NxN):
 * @param coordBase pixel position to calculate the filter sum from
 * @return calculated filter sum
 */
/* GENERATE_TYPE */ filter_sum_MULTIPLICITY_DERIV_NxN(global float* imgIn,
                                                      constant struct Lookup* locationLookup/* GENERATE_REMOVE_PREDEFINED:,
                                                      constant float* filterKernel/* GENERATE_DOUBLE:1,
                                                      constant float* filterKernel2*/*/,
                                                      const int filterRowsHalf,   // GENERATE_REMOVE
                                                      const int filterCols,       // GENERATE_REMOVE
                                                      const int filterColsHalf,   // GENERATE_REMOVE
                                                      const int3 coordBase,
                                                      const int border)
{
    /* GENERATE_TYPE */ sum = (/* GENERATE_TYPE */)(0.0f/* GENERATE_DOUBLE:, 0.0f*/);
    const int rows = locationLookup[coordBase.z].imgHeight;
    const int cols = locationLookup[coordBase.z].imgWidth;
    int3 coordCurrent;
    int3 coordBorder;
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
            color = readValue(imgIn, locationLookup, coordBorder.z, coordBorder.x, coordBorder.y);

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
 * @param locationLookup lookup table to access the pixels in the scale space
 * @param imgOut image containing the filter response
 * @param filterKernel 1D array with the filter values. The filter is centred on the current pixel and the size of the filter must be odd
 * @param filterRowsHalf rows of the filter divided by 2 with int cast, i.e. filterRowsHalf = floor(filterRows / 2) // GENERATE_REMOVE
 * @param filterCols cols of the filter // GENERATE_REMOVE
 * @param filterColsHalf cols of the filter divided by 2 with int cast, i.e. filterColsHalf = floor(filterCols / 2) // GENERATE_REMOVE
 * @param border int value which specifies how out-of-border accesses should be handled. The values correspond to the OpenCV border types
 */
kernel void filter_MULTIPLICITY_DERIV_NxN(global float* imgIn,
                                          constant struct Lookup* locationLookup,
                                          global float* imgOut/* GENERATE_DOUBLE:1,
                                          global float* imgOut2*//* GENERATE_REMOVE_PREDEFINED:,
                                          constant float* filterKernel/* GENERATE_DOUBLE:1,
                                          constant float* filterKernel2*/*/,
                                          const int filterRowsHalf, // GENERATE_REMOVE
                                          const int filterCols,     // GENERATE_REMOVE
                                          const int filterColsHalf, // GENERATE_REMOVE
                                          const int border)
{
    int3 coordBase = (int3)(get_global_id(0), get_global_id(1), get_global_id(2));

    /* GENERATE_TYPE */ sum = filter_sum_MULTIPLICITY_DERIV_NxN(imgIn, locationLookup/* GENERATE_REMOVE_PREDEFINED:, filterKernel/* GENERATE_DOUBLE:1, filterKernel2*/*/,/* GENERATE_REMOVE: filterRowsHalf, filterCols, filterColsHalf,*/ coordBase, border);

    writeValue(imgOut/* GENERATE_DOUBLE:1*/, locationLookup, coordBase.z, coordBase.x, coordBase.y, sum/* GENERATE_DOUBLE:.x*/);
    /* GENERATE_DOUBLE:writeValue(imgOut2, locationLookup, coordBase.z, coordBase.x, coordBase.y, sum.y);*/
}
