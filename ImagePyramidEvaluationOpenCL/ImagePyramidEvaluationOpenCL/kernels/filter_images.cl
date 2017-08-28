#include "shared_variables.h"

#define BORDER_REPLICATE 1   //!< `aaaaaa|abcdefgh|hhhhhhh`
#define BORDER_REFLECT_101 4 //!< `gfedcb|abcdefgh|gfedcba`

/**
 * Calculates the adjusted border coordinated based on the border type.
 */
int2 borderCoordinate(int2 coord, int rows, int cols, int border)
{
    int2 coordAdjusted = coord;

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

#include "filter_images_normal.cl"
#include "filter_images_local.cl"
#include "filter_images_predefined-normal.cl"
#include "filter_images_predefined-local.cl"

/**
 * @see https://github.com/opencv/opencv/blob/master/modules/imgproc/src/opencl/resize.cl
 */
kernel void fed_resize(read_only image2d_t imgSrc,
                       write_only image2d_t imgDst)
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
                const float val = read_imagef(imgSrc, sampler, (int2)(x, y)).x;
                sum += val;
                //sum += convertToWTV(loadpix(src + src_index + x*TSIZE));
            }
        }

        write_imagef(imgDst, (int2)(dx, dy), sum * SCALE);
        //storepix(convertToT(convertToWT2V(sum) * (WT2V)(SCALE)), dst + mad24(dx, TSIZE, dst_index));
    }
}
