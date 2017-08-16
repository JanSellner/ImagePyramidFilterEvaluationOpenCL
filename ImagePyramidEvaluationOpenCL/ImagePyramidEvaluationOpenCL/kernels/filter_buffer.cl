#include "shared_variables.h"

#define BORDER_REPLICATE 1   //!< `aaaaaa|abcdefgh|hhhhhhh`
#define BORDER_REFLECT_101 4 //!< `gfedcb|abcdefgh|gfedcba`

int3 borderCoordinate(int3 coord, int rows, int cols, int border)
{
    int3 coordAdjusted = coord;

    if (border == BORDER_REFLECT_101)
    {
        if (coord.x < 0)
        {
            coordAdjusted.x = abs(coord.x); // -1 --> 1
        }
        if (coord.y < 0)
        {
            coordAdjusted.y = abs(coord.y);
        }
        if (coord.x >= cols)
        {
            // 8 --> 6
            coordAdjusted.x = cols - (coord.x - cols);
        }
        if (coord.y >= rows)
        {
            coordAdjusted.y = rows - (coord.y - rows);
        }
    }
    // BORDER_REPLICATE is the default setting of the used sampler

    return coordAdjusted;
}

float filter_sum(global float* img,
                 constant struct Lookup* locationLookup,
                 constant float* filterKernel,
                 const int filterRows,
                 const int filterRowsHalf,
                 const int filterCols,
                 const int filterColsHalf,
                 const int3 coord0,
                 const int border)
{
    const int rows = locationLookup[coord0.z].imgHeight;
    const int cols = locationLookup[coord0.z].imgWidth;

    float sum = 0.0f;
    int3 coord;
    coord.z = coord0.z;
    // Image patch is row-wise accessed
    for (int y = -filterRowsHalf; y <= filterRowsHalf; ++y)
    {
        coord.y = coord0.y + y;
        for (int x = -filterColsHalf; x <= filterColsHalf; ++x)
        {
            coord.x = coord0.x + x;
            const int3 coordBorder = borderCoordinate(coord, rows, cols, border);
            float color = readValue(img, locationLookup, coordBorder.z, coordBorder.x, coordBorder.y);

            sum += color * filterKernel[(y + filterRowsHalf) * filterCols + x + filterColsHalf];
        }
    }

    return sum;
}

float filter_sum_local(global float* img,
                       constant struct Lookup* locationLookup,
                       constant float* filterKernel,
                       const int filterRows,
                       const int filterRowsHalf,
                       const int filterCols,
                       const int filterColsHalf,
                       const int3 coord0,
                       const int border)
{
    float sum = 0.0f;
    const int x = get_global_id(0);
    const int y = get_global_id(1);
    const int rows = locationLookup[coord0.z].imgHeight;
    const int cols = locationLookup[coord0.z].imgWidth;

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
            int3 coordBorder = borderCoordinate((int3)(xx - filterColsHalf + xBase, yy - filterRowsHalf + yBase, coord0.z), rows, cols, border);
            localBuffer[yy * LOCAL_SIZE + xx] = readValue(img, locationLookup, coordBorder.z, coordBorder.x, coordBorder.y);
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
kernel void filter_single(global float* imgIn,
                          global float* imgOut,
                          constant struct Lookup* locationLookup,
                          constant float* filterKernel,
                          const int filterRows,
                          const int filterRowsHalf,
                          const int filterCols,
                          const int filterColsHalf,
                          const int border)
{
    int3 coord0 = (int3)(get_global_id(0), get_global_id(1), get_global_id(2));

    float sum = filter_sum(imgIn, locationLookup, filterKernel, filterRows, filterRowsHalf, filterCols, filterColsHalf, coord0, border);

    writeValue(imgOut, locationLookup, coord0.z, coord0.x, coord0.y, sum);
}

kernel void filter_single_local(global float* imgIn,
                                global float* imgOut,
                                constant struct Lookup* locationLookup,
                                constant float* filterKernel,
                                const int filterRows,
                                const int filterRowsHalf,
                                const int filterCols,
                                const int filterColsHalf,
                                const int border)
{
    int3 coord0 = (int3)(get_global_id(0), get_global_id(1), get_global_id(2));

    float sum = filter_sum_local(imgIn, locationLookup, filterKernel, filterRows, filterRowsHalf, filterCols, filterColsHalf, coord0, border);

    writeValue(imgOut, locationLookup, coord0.z, coord0.x, coord0.y, sum);
}

/**
 * @see https://github.com/opencv/opencv/blob/master/modules/imgproc/src/opencl/resize.cl
 */
kernel void fed_resize(global float* img,
                       constant struct Lookup* locationLookup,
                       const int class_id)
{
    const int dx = get_global_id(0);
    const int dy = get_global_id(1);
    const int dst_cols = locationLookup[class_id + 1].imgWidth;
    const int dst_rows = locationLookup[class_id + 1].imgHeight;
    const int src_cols = locationLookup[class_id].imgWidth;
    const int src_rows = locationLookup[class_id].imgHeight;
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
                const float val = readValue(img, locationLookup, class_id, x, y);
                sum += val;
                //sum += convertToWTV(loadpix(src + src_index + x*TSIZE));
            }
        }

        writeValue(img, locationLookup, class_id + 1, dx, dy, sum * SCALE);
        //storepix(convertToT(convertToWT2V(sum) * (WT2V)(SCALE)), dst + mad24(dx, TSIZE, dst_index));
    }
}

kernel void copy_inside_cube(global float* img,
                             constant struct Lookup* locationLookup,
                             const int class_id)
{
    const int x = get_global_id(0);
    const int y = get_global_id(1);
    const int z = get_global_id(2);

    const float val = readValue(img, locationLookup, class_id, x, y);

    writeValue(img, locationLookup, z, x, y, val);
}
