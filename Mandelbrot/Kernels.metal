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
// adapted from Andrew Thall (SIGGRAPH 2006)

// quick two-sum of floating point numbers
inline float2 q2sum(float a, float b) {
    float s = a + b, e = b - (s - a);
    
    return float2(s, e);
}

// coalesced two-sum of double-floats
inline float4 c2sum(float2 a, float2 b) {
    float2 s = a + b, t = s - a, e = (a - (s - t)) + (b - t);
    
    return float4(s.x, e.x, s.y, e.y);
}

// general sum of double-float numbers
inline float2 df64_add(float2 a, float2 b) {
    float4 s = c2sum(a, b);
    
    s.y += s.z; s.xy = q2sum(s.x, s.y);
    s.y += s.w; s.xy = q2sum(s.x, s.y);
    
    return s.xy;
}

// coalesced split of 32-bit floats into high and low order terms
inline float4 csplit(float2 a) {
    const float split = 4097; // (1 << 12) + 1
    float2 t = a * split, hi = t - (t - a), lo = a - hi;
    
    return float4(hi.x, lo.x, hi.y, lo.y);
}

// quick two-product of floating point numbers
inline float2 qprod(float a, float b) {
    float4 s = csplit(float2(a,b));
    float p = a*b, e = ((s.x*s.z - p) + s.x*s.w + s.y*s.z) + s.y*s.w;
    
    return float2(p, e);
}

// general product of double-float numbers
inline float2 df64_mul(float2 a, float2 b) {
    float2 p = qprod(a.x, b.x);
    
    p.y += a.x*b.y;
    p.y += a.y*b.x;
    p = q2sum(p.x, p.y);
    
    return p;
}

