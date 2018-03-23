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
    var theta: CGFloat = 0.0
    var scale: CGFloat = 1.0 {
        didSet {
            if scale < 1.0e-8 { scale = 1.0e-8 }
            if scale > 1.0e-2 { scale = 1.0e-2 }
        }
    }
    var shift: CGPoint = CGPoint.zero
    
    var rotation: CGAffineTransform {
        let a = scale * cos(theta), b = scale * sin(theta)
        return CGAffineTransform(a: a, b: b, c: -b, d: a, tx: 0, ty: 0)
    }
    
    var map: CGAffineTransform {
        let a = scale * cos(theta), b = scale * sin(theta)
        let x = shift.x - (a * drawableSize.width - b * drawableSize.height)/2.0
        let y = shift.y - (b * drawableSize.width + a * drawableSize.height)/2.0
        return CGAffineTransform(a: a, b: b, c: -b, d: a, tx: x, ty: y)
    }
    
    // MARK: center fractal on the screen
    @IBAction func home(_ sender: AnyObject?) {
        scale = max(3.0/drawableSize.width, 2.0/drawableSize.height)
        shift = CGPoint(x: -0.6, y: 0.0); theta = 0.0
    }
    
    // MARK: gesture recognizers
    var tap = UITapGestureRecognizer()
    var pan = UIPanGestureRecognizer()
    var pinch = UIPinchGestureRecognizer()
    var turn = UIRotationGestureRecognizer()
    
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
        turn.addTarget(self, action: #selector(rotate)); addGestureRecognizer(turn)
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
    
    // MARK: drag the view
    @IBAction func drag(_ gesture: UIPanGestureRecognizer) {
        let delta = gesture.translation(in: self) * contentScaleFactor
        
        shift -= delta.applying(rotation)
        gesture.setTranslation(CGPoint.zero, in: self)
    }
    
    // MARK: zoom the view
    @IBAction func zoom(_ gesture: UIPinchGestureRecognizer) {
        let center = gesture.location(in: self) * contentScaleFactor
        
        let a = center.applying(map)
        scale /= gesture.scale; gesture.scale = 1.0
        let b = center.applying(map)
        
        shift += a-b
    }
    
    // MARK: rotate the view
    @IBAction func rotate(_ gesture: UIRotationGestureRecognizer) {
        let center = gesture.location(in: self) * contentScaleFactor
        
        let a = center.applying(map)
        theta -= gesture.rotation; gesture.rotation = 0.0
        let b = center.applying(map)
        
        shift += a-b
    }
}
