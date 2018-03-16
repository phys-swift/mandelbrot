//
//  Kernels.metal
//  Mandelbrot
//
//  Created by Andrei Frolov on 2018-03-14.
//  Copyright © 2018 SFU Physics Department. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void mandelbrot(
    texture2d<float,access::write>      output [[ texture(0) ]],
    constant float3x2 &transform        [[ buffer(0) ]],
    uint2 gid                           [[ thread_position_in_grid ]]
) {
    const float2 c = transform * float3(gid.x, gid.y, 1);
    float2 z = c; float w = 0.0; const ushort n = 20;
    
    // escape time iteration
    for (ushort i = 0; i < n; i++) {
        z = float2(z.x*z.x-z.y*z.y, 2.0*z.x*z.y) + c;
        if (dot(z,z) > 4.0) { w = 1.0/(n-i); break; }
    }
    
    // apply rendering colormap
    float4 pixel = float4(0.0, 4.0*w, 8.0*w, 1.0);
    
    output.write(pixel, gid);
}
