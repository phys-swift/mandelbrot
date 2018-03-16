//
//  MandelbrotView.swift
//  Mandelbrot
//
//  Created by Andrei Frolov on 2018-03-14.
//  Copyright © 2018 SFU Physics Department. All rights reserved.
//

import UIKit
import MetalKit

class MandelbrotView: MTKView {
    // compute pipeline
    var buffer: MTLBuffer! = nil
    var queue: MTLCommandQueue! = nil
    let shader = MetalKernel(kernel: "mandelbrot")
    
    // viewport geometry
    var shift: CGPoint = CGPoint.zero
    var scale: CGFloat = 1.0
    
    var map: CGAffineTransform {
        let x = shift.x - (scale/2.0)*drawableSize.width
        let y = shift.y - (scale/2.0)*drawableSize.height
        return CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: x, ty:y)
    }
    
    @IBAction func home(_ sender: AnyObject?) {
        scale = max(3.0/drawableSize.width, 2.0/drawableSize.height)
        shift = CGPoint(x: -0.6, y: 0.0)
    }
    
    // initalize after being decoded
    override func awakeFromNib() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let buffer = device.makeBuffer(length: MemoryLayout<float3x2>.size),
              let queue = device.makeCommandQueue()
              else { fatalError("Metal Framework could not be initalized") }
        
        self.device = device
        self.buffer = buffer
        self.queue = queue
        
        framebufferOnly = false
        super.awakeFromNib()
        home(self)
    }
    
    // render image in Metal view
    override func draw(_ rect: CGRect) {
        // check that we have a draw destination
        guard currentRenderPassDescriptor != nil, let drawable = currentDrawable else { return }
        
        // update coordinate map buffer for GPU kernel
        buffer.contents().storeBytes(of: map.float3x2, as: float3x2.self)
        
        // initialize compute command buffer
        guard let command = queue.makeCommandBuffer() else { return }
        shader.encode(command: command, buffers: [buffer], textures: [drawable.texture])
        command.present(drawable)
        command.commit()
    }
}
