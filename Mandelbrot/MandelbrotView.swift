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
    // initalize after being decoded
    override func awakeFromNib() {
        super.awakeFromNib(); device = MTLCreateSystemDefaultDevice()
        guard device != nil else { fatalError("Metal Framework could not be initalized") }
        
        framebufferOnly = false
    }
    
    // render image in Metal view
    override func draw(_ rect: CGRect) {
        // check that we have a draw destination
        guard currentRenderPassDescriptor != nil, let drawable = currentDrawable else { return }
        
        // render stuff here...
        print("draw() got called")
    }
}
