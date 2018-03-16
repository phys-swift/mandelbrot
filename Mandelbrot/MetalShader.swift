//
//  MetalShader.swift
//  Mandelbrot
//
//  Created by Andrei Frolov on 2018-03-14.
//  Copyright © 2018 SFU Physics Department. All rights reserved.
//

import Foundation
import MetalKit

// MARK: SIMD data type bindings of Core Graphics affine transform components for Metal API
extension CGAffineTransform {
    var float3x2: float3x2 { return simd.float3x2(float2(Float(a),Float(b)), float2(Float(c),Float(d)), float2(Float(tx),Float(ty))) }
    init(m: float3x2) { self.init(a: CGFloat(m[0,0]), b: CGFloat(m[0,1]), c: CGFloat(m[1,0]), d: CGFloat(m[1,1]), tx: CGFloat(m[2,0]), ty: CGFloat(m[2,1])) }
}

// MARK: convenience extensions to MTLTexture
extension MTLTexture {
    // texture size and CIImage-style extent
    var size: MTLSize { return MTLSize(width: width, height: height, depth: depth) }
    var extent: CGRect { return CGRect(x: 0, y: 0, width: width, height: height) }
}

// MARK: protocol encapsulating a Metal operation that can be encoded into a single command buffer
protocol MetalShader {
    var name: String { get }
    
    // encode shader to command buffer specified
    func encode(command: MTLCommandBuffer, textures: [MTLTexture])
    func encode(command: MTLCommandBuffer, textures: MTLTexture...)
    func encode(command: MTLCommandBuffer, buffers: [MTLBuffer], textures: [MTLTexture], threadsPerGrid: MTLSize?)
    func encode(command: MTLCommandBuffer, buffers: [Int: MTLBuffer], textures: [Int: MTLTexture], threadsPerGrid: MTLSize)
}

extension MetalShader {
    // default implementation of encode with arguments passed as dictionaries
    func encode(command: MTLCommandBuffer, buffers buffer: [Int: MTLBuffer], textures texture: [Int: MTLTexture], threadsPerGrid: MTLSize) {
        var buffers = [MTLBuffer](), i = 0
        buffers.reserveCapacity(buffer.count)
        while let b = buffer[i] { buffers.append(b); i += 1 }
        
        var textures = [MTLTexture](), j = 0
        textures.reserveCapacity(texture.count)
        while let t = texture[j] { textures.append(t); j += 1 }
        
        encode(command: command, buffers: buffers, textures: textures, threadsPerGrid: threadsPerGrid)
    }
    
    // convenience encoders which operate on textures only
    func encode(command: MTLCommandBuffer, textures: [MTLTexture]) {
        encode(command: command, buffers: [], textures: textures, threadsPerGrid: nil)
    }
    
    func encode(command: MTLCommandBuffer, textures literal: MTLTexture...) {
        encode(command: command, buffers: [], textures: literal, threadsPerGrid: nil)
    }
}

// MARK: structure encapsulating a single Metal compute function
struct MetalKernel: MetalShader {
    let name: String
    let state: MTLComputePipelineState
    var threadsPerGroup: MTLSize
    
    // main initializer
    init(kernel: String, device provided: MTLDevice? = nil) {
        guard let device = provided ?? MTLCreateSystemDefaultDevice()
            else { fatalError("Metal Framework could not be initalized") }
        
        guard let library = device.makeDefaultLibrary(),
            let function = library.makeFunction(name: kernel),
            let state = try? device.makeComputePipelineState(function: function)
            else { fatalError("Unable to create pipeline state for kernel function \(kernel)") }
        
        // compute pipeline
        self.name = kernel
        self.state = state
        
        // default thread group configuration
        let threads = state.maxTotalThreadsPerThreadgroup, width = state.threadExecutionWidth
        threadsPerGroup = MTLSize(width: width, height: threads/width, depth: 1)
    }
    
    // dispatch compute encoder threads for execution
    func dispatch(_ encoder: MTLComputeCommandEncoder, threadsPerGrid: MTLSize) {
        // dispatchThreads does not work on devices as recent as iPhone 7
        // encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        
        // dispatch thread groups to cover entire grid
        let w = (threadsPerGrid.width + threadsPerGroup.width - 1)/threadsPerGroup.width
        let h = (threadsPerGrid.height + threadsPerGroup.height - 1)/threadsPerGroup.height
        let groupsPerGrid = MTLSize(width: w, height: h, depth: 1)
        encoder.dispatchThreadgroups(groupsPerGrid, threadsPerThreadgroup: threadsPerGroup)
    }
    
    // encode kernel into provided command buffer, with arguments passed as dictionaries
    func encode(command: MTLCommandBuffer, buffers: [Int: MTLBuffer], textures: [Int: MTLTexture], threadsPerGrid: MTLSize) {
        // initialize compute command encoder for kernel execution
        guard let encoder = command.makeComputeCommandEncoder() else { return }
        
        // encode kernel for execution and set its arguments
        encoder.setComputePipelineState(state)
        for (index, buffer) in buffers { encoder.setBuffer(buffer, offset: 0, index: index) }
        for (index, texture) in textures { encoder.setTexture(texture, index: index) }
        
        // dispatch compute pass and end command encoding
        dispatch(encoder, threadsPerGrid: threadsPerGrid); encoder.endEncoding()
    }
    
    // encode kernel into provided command buffer, with arguments passed as arrays
    func encode(command: MTLCommandBuffer, buffers: [MTLBuffer], textures: [MTLTexture], threadsPerGrid provided: MTLSize? = nil) {
        // initialize compute command encoder for kernel execution
        guard let threadsPerGrid = provided ?? textures.last?.size else { return }
        guard let encoder = command.makeComputeCommandEncoder() else { return }
        
        // encode kernel for execution and set its arguments
        encoder.setComputePipelineState(state)
        for (index, buffer) in buffers.enumerated() { encoder.setBuffer(buffer, offset: 0, index: index) }
        for (index, texture) in textures.enumerated() { encoder.setTexture(texture, index: index) }
        
        // dispatch compute pass and end command encoding
        dispatch(encoder, threadsPerGrid: threadsPerGrid); encoder.endEncoding()
    }
}
