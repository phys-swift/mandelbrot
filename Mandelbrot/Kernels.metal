//
//  Kernels.metal
//  Mandelbrot
//
//  Created by Andrei Frolov on 2018-03-14.
//  Copyright © 2018 SFU Physics Department. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// MARK: single precision Mandelbrot renderer - textbook implementation
kernel void mandelbrot(
    texture2d<float,access::write>      output [[ texture(0) ]],
    constant float3x2 &transform        [[ buffer(0) ]],
    uint2 gid                           [[ thread_position_in_grid ]]
) {
    const float2 c = transform * float3(gid.x, gid.y, 1);
    float2 z = c; float w = 0.0; const ushort n = 100;
    
    // escape time iteration
    for (ushort i = 0; i < n; i++) {
        z = float2(z.x*z.x-z.y*z.y, 2.0*z.x*z.y) + c;
        if (dot(z,z) > 4.0) { w = 5.0/(n-i + log(log(dot(z,z)))/log(2.0)); break; }
    }
    
    // apply rendering colormap
    float4 pixel = float4(0.0, 4.0*w, 8.0*w, 1.0);
    
    output.write(pixel, gid);
}

// MARK: extended precision floating point operations
// algorithms adapted from Andrew Thall (SIGGRAPH 2006)

// quick two-sum of floating point numbers
inline float2 q2sum(float a, float b) {
    float s = a + b, e = b - (s - a);
    
    return float2(s, e);
}

// general sum of double-float numbers
inline float2 df64_add(float2 a, float2 b) {
    float2 s = a + b, t = s - a, e = (a - (s - t)) + (b - t);
    
    s = q2sum(s.x, s.y + e.x);
    s = q2sum(s.x, s.y + e.y);
    
    return s;
}

// general product of double-float numbers
inline float2 df64_mul(float2 a, float2 b) {
    float2 u = float2(a.x,b.x), t = 4097 * u, hi = t - (t - u), lo = u - hi;
    float p = a.x*b.x, e = ((hi.x*hi.y - p) + hi.x*lo.y + lo.x*hi.y) + lo.x*lo.y;
    
    return q2sum(p, e + a.x*b.y + a.y*b.x);
}

