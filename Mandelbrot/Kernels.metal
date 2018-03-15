//
//  Kernels.metal
//  Mandelbrot
//
//  Created by Andrei Frolov on 2018-03-14.
//  Copyright © 2018 SFU Physics Department. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void checkerboard(
    texture2d<float,access::write>      output [[ texture(0) ]],
    uint2 gid                           [[ thread_position_in_grid ]]
) {
    constexpr float4 bg0 = float4(0);
    constexpr float4 bg1 = float4(1);
    float4 pixel = select(bg0, bg1, ((gid.x >> 4) + (gid.y >> 4)) & 1);
    
    output.write(pixel, gid);
}
