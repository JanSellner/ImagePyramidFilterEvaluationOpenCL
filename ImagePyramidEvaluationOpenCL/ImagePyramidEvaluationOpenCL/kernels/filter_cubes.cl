#include "shared_variables.h"

#define BORDER_REPLICATE 1   //!< `aaaaaa|abcdefgh|hhhhhhh`
#define BORDER_REFLECT_101 4 //!< `gfedcb|abcdefgh|gfedcba`

/**
 * Calculates the adjusted border coordinated based on the border type.
 */
int4 borderCoordinate(int4 coord, int rows, int cols, int border)
{
    int4 coordAdjusted = coord;

    if (border == BORDER_REFLECT_101)
    {
        // Consider the following 1D example
        // -2 -1 | 0 1 2 3 | 4 5
        // cols = 4

        // Left
        if (coord.x < 0)
        {
            coordAdjusted.x = abs(coord.x); // |-1| --> 1
        }

        // Top
        if (coord.y < 0)
        {
            coordAdjusted.y = abs(coord.y);
        }
        
        // Right
        if (coord.x >= cols)
        {
            // 5 --> 1
            // coord.x - cols + 1 = 5 - 4 + 1 = 2   (= how far passed the coordinate the border?)
            // cols - (coord.x - cols + 1) - 1 = 4 - 2 - 1 = 1
            coordAdjusted.x = cols - (coord.x - cols + 1) - 1;  // -1 since the last value is not repeated
        }

        // Bottom
        if (coord.y >= rows)
        {
            coordAdjusted.y = rows - (coord.y - rows + 1) - 1;
        }
    }
    // BORDER_REPLICATE is the default setting of the used sampler

    return coordAdjusted;
}

float filter_sum(read_only image2d_array_t imgIn,
                 constant float* filterKernel,
                 const int filterRows,
                 const int filterRowsHalf,
                 const int filterCols,
                 const int filterColsHalf,
                 const int4 coord0,
                 const int border)
{
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    float sum = 0.0f;
    int4 coord;
    coord.z = coord0.z;

    // Image patch is row-wise accessed
    for (int y = -filterRowsHalf; y <= filterRowsHalf; ++y)
    {
        coord.y = coord0.y + y;
        for (int x = -filterColsHalf; x <= filterColsHalf; ++x)
        {
            coord.x = coord0.x + x;
            const int4 coordBorder = borderCoordinate(coord, rows, cols, border);
            float color = read_imagef(imgIn, sampler, coordBorder).x;

            sum += color * filterKernel[(y + filterRowsHalf) * filterCols + x + filterColsHalf];
        }
    }

    return sum;
}

float filter_sum_local(read_only image2d_array_t imgIn,
                       constant float* filterKernel,
                       const int filterRows,
                       const int filterRowsHalf,
                       const int filterCols,
                       const int filterColsHalf,
                       const int4 coord0,
                       const int border)
{
    float sum = 0.0f;
    const int x = get_global_id(0);
    const int y = get_global_id(1);
    const int rows = get_image_height(imgIn);
    const int cols = get_image_width(imgIn);

    const int xLocal = get_local_id(0) + filterColsHalf;
    const int yLocal = get_local_id(1) + filterRowsHalf;

#define LOCAL_SIZE 24 //(16 + 2 * 4)
    local float localBuffer[LOCAL_SIZE * LOCAL_SIZE];

    int xLocalId = get_local_id(0);
    int yLocalId = get_local_id(1);

    int xLocalSize = get_local_size(0);
    int yLocalSize = get_local_size(1);

    int xBase = x - xLocalId;
    int yBase = y - yLocalId;

    /*
     * Copy data to local memory by applying the following pattern (involves max 4 reads)
     * 111122
     * 333344
     */
    for (int yy = yLocalId; yy < yLocalSize + 2 * filterRowsHalf; yy += yLocalSize)
    {
        for (int xx = xLocalId; xx < xLocalSize + 2 * filterColsHalf; xx += xLocalSize)
        {
            int4 coordBorder = borderCoordinate((int4)(xx - filterColsHalf + xBase, yy - filterRowsHalf + yBase, coord0.z, 0), rows, cols, border);
            localBuffer[yy * LOCAL_SIZE + xx] = read_imagef(imgIn, sampler, coordBorder).x;
        }
    }

    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    int2 coord0Local = (int2)(xLocal, yLocal);
    int2 coord;
    
    // Image patch is row-wise accessed
    for (int y = -filterRowsHalf; y <= filterRowsHalf; ++y)
    {
        coord.y = coord0Local.y + y;
        for (int x = -filterColsHalf; x <= filterColsHalf; ++x)
        {
            coord.x = coord0Local.x + x;
            float color = localBuffer[coord.y * LOCAL_SIZE + coord.x];

            sum += color * filterKernel[(y + filterRowsHalf) * filterCols + x + filterColsHalf];
        }
    }

    return sum;
}

/**
 * @brief Convolution for one filter.
 */
kernel void filter_single(read_only image2d_array_t imgIn,
                          write_only image2d_array_t imgOut,
                          constant float* filterKernel,
                          const int filterRows,
                          const int filterRowsHalf,
                          const int filterCols,
                          const int filterColsHalf,
                          const int border)
{
    int4 coord0 = (int4)(get_global_id(0), get_global_id(1), get_global_id(2), 0);

    float sum = filter_sum(imgIn, filterKernel, filterRows, filterRowsHalf, filterCols, filterColsHalf, coord0, border);

    write_imagef(imgOut, coord0, sum);
}

kernel void filter_single_local(read_only image2d_array_t imgIn,
                                write_only image2d_array_t imgOut,
                                constant float* filterKernel,
                                const int filterRows,
                                const int filterRowsHalf,
                                const int filterCols,
                                const int filterColsHalf,
                                const int border)
{
    int4 coord0 = (int4)(get_global_id(0), get_global_id(1), get_global_id(2), 0);

    float sum = filter_sum_local(imgIn, filterKernel, filterRows, filterRowsHalf, filterCols, filterColsHalf, coord0, border);

    write_imagef(imgOut, coord0, sum);
}

/**
 * @see https://github.com/opencv/opencv/blob/master/modules/imgproc/src/opencl/resize.cl
 */
kernel void fed_resize(read_only image2d_array_t imgSrc,
                       write_only image2d_array_t imgDst)
{
    const int dx = get_global_id(0);
    const int dy = get_global_id(1);
    const int dst_cols = get_image_width(imgDst);
    const int dst_rows = get_image_height(imgDst);
    const int src_cols = get_image_width(imgSrc);
    const int src_rows = get_image_height(imgSrc);
    const int dst_step = 1;
    const int dst_offset = 0;
    const int src_step = 1;
    const int src_offset = 0;
    const float XSCALE = 2.0f;
    const float YSCALE = 2.0f;
    const float SCALE = 0.25f;

    if (dx < dst_cols && dy < dst_rows)
    {
        int dst_index = mad24(dy, dst_step, dst_offset);

        int sx = XSCALE * dx;
        int sy = YSCALE * dy;
        float sum = 0.0f;
        //WTV sum = (WTV)(0);

        #pragma unroll
        for (int py = 0; py < YSCALE; ++py)
        {
            int y = min(sy + py, src_rows - 1);
            int src_index = mad24(y, src_step, src_offset);
            #pragma unroll
            for (int px = 0; px < XSCALE; ++px)
            {
                int x = min(sx + px, src_cols - 1);
                const float val = read_imagef(imgSrc, sampler, (int4)(x, y, 3, 0)).x;
                sum += val;
                //sum += convertToWTV(loadpix(src + src_index + x*TSIZE));
            }
        }

        write_imagef(imgDst, (int4)(dx, dy, 0, 0), sum * SCALE);
        //storepix(convertToT(convertToWT2V(sum) * (WT2V)(SCALE)), dst + mad24(dx, TSIZE, dst_index));
    }
}

kernel void copy_inside_cube(read_write image2d_array_t imgArray)
{
    const int x = get_global_id(0);
    const int y = get_global_id(1);
    const int z = get_global_id(2);

    const float val = read_imagef(imgArray, sampler, (int4)(x, y, 0, 0)).x;

    write_imagef(imgArray, (int4)(x, y, z, 0), val);
}
