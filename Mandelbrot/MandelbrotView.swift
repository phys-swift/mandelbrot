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
    // MARK: compute pipeline
    var buffer: MTLBuffer! = nil
    var queue: MTLCommandQueue! = nil
    let shader = MetalKernel(kernel: "mandelbrot")
    
    // MARK: viewport geometry
    var shift: CGPoint = CGPoint.zero
    var scale: CGFloat = 1.0 {
        didSet {
            if scale < 1.0e-8 { scale = 1.0e-8 }
            if scale > 1.0e-2 { scale = 1.0e-2 }
        }
    }
    
    var map: CGAffineTransform {
        let x = shift.x - (scale/2.0)*drawableSize.width
        let y = shift.y - (scale/2.0)*drawableSize.height
        return CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: x, ty:y)
    }
    
    @IBAction func home(_ sender: AnyObject?) {
        scale = max(3.0/drawableSize.width, 2.0/drawableSize.height)
        shift = CGPoint(x: -0.6, y: 0.0)
    }
    
    // MARK: gesture recognizers
    var tap = UITapGestureRecognizer()
    var pan = UIPanGestureRecognizer()
    var pinch = UIPinchGestureRecognizer()
    
    // MARK: initalize after being decoded
    override func awakeFromNib() {
        // initialize MTKView
        super.awakeFromNib()
        
        // initialize compute pipeline
        guard let device = MTLCreateSystemDefaultDevice(),
              let buffer = device.makeBuffer(length: MemoryLayout<float3x2>.size),
              let queue = device.makeCommandQueue()
              else { fatalError("Metal Framework could not be initalized") }
        
        self.device = device
        self.buffer = buffer
        self.queue = queue
        
        framebufferOnly = false
        home(self)
        
        // add gesture recognisers
        tap.numberOfTapsRequired = 2; pan.maximumNumberOfTouches = 1
        tap.addTarget(self, action: #selector(home)); addGestureRecognizer(tap)
        pan.addTarget(self, action: #selector(drag)); addGestureRecognizer(pan)
        pinch.addTarget(self, action: #selector(zoom)); addGestureRecognizer(pinch)
    }
    
    // MARK: render image in Metal view
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
    
    // MARK: drag the view around the screen
    var origin = CGPoint.zero
    
    @IBAction func drag(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            origin = shift
        case .changed, .ended:
            let t = gesture.translation(in: self)
            shift = CGPoint(x: origin.x - contentScaleFactor * scale * t.x, y: origin.y - contentScaleFactor*scale*t.y)
        case .cancelled:
            shift = origin
        default: break
        }
    }
    
    // MARK: zoom the view
    @IBAction func zoom(_ gesture: UIPinchGestureRecognizer) {
        let center = gesture.location(in: self) * contentScaleFactor
        
        let a = center.applying(map)
        scale /= gesture.scale; gesture.scale = 1.0
        let b = center.applying(map)
        
        shift += a-b
    }
}
