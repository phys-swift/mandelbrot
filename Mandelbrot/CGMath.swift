//
//  CGMath.swift
//  Mandelbrot
//
//  Created by Andrei Frolov on 2018-03-22.
//  Copyright © 2018 SFU Physics Department. All rights reserved.
//

import UIKit

extension CGAffineTransform {
    // convenience initializers
    init(scale: CGFloat) { self.init(scaleX: scale, y: scale) }
    init(shift: CGPoint) { self.init(translationX: shift.x, y: shift.y) }
    init(shift: CGSize) { self.init(translationX: shift.width, y: shift.height) }
    
    // principal decomposition Q = rotation(alpha)*diag(p,q)*rotation(beta) + shift
    var SVD: (p: CGFloat, q: CGFloat, alpha: CGFloat, beta: CGFloat) {
        let phi = atan2(self.b-self.c, self.d+self.a)   // alpha + beta
        let psi = atan2(self.b+self.c, self.d-self.a)   // alpha - beta
        let u = (self.a+self.d)/cos(phi)                // p + q
        let v = (self.a-self.d)/cos(psi)                // p - q
        
        return (p: (u+v)/2.0, q: (u-v)/2.0, alpha: (phi+psi)/2.0, beta: (phi-psi)/2.0)
    }
    
    // individual parameters
    var alpha: CGFloat { return self.SVD.alpha }
    var beta:  CGFloat { return self.SVD.beta  }
    var scale: CGPoint { let svd = self.SVD; return CGPoint(x: svd.p, y: svd.q) }
    var shift: CGPoint { return CGPoint(x: self.tx, y: self.ty) }
    var size: CGSize { return CGSize(width: self.tx, height: self.ty) }
}

// affine transform composition, applied from left to right, i.e. (A*B)(I) = B(A(I))
func *(A: CGAffineTransform, B: CGAffineTransform) -> CGAffineTransform { return A.concatenating(B) }

// single float represents uniform scaling, same associativity rules
func *(A: CGAffineTransform, s: CGFloat) -> CGAffineTransform { return A.concatenating(CGAffineTransform(scale: s)) }
func *(s: CGFloat, A: CGAffineTransform) -> CGAffineTransform { return A.scaledBy(x: s, y: s) }

// scaling of vectors, defined from the right to keep consistent order
func *(p: CGPoint, s: CGFloat) -> CGPoint { return CGPoint(x: p.x*s, y: p.y*s) }
func /(p: CGPoint, s: CGFloat) -> CGPoint { return CGPoint(x: p.x/s, y: p.y/s) }
func *(q: CGSize,  s: CGFloat) -> CGSize  { return CGSize(width: q.width*s, height: q.height*s) }
func /(q: CGSize,  s: CGFloat) -> CGSize  { return CGSize(width: q.width/s, height: q.height/s) }

// single vector represents translation, same associativity rules
func +(A: CGAffineTransform, p: CGPoint) -> CGAffineTransform { return A.concatenating(CGAffineTransform(shift:  p)) }
func -(A: CGAffineTransform, p: CGPoint) -> CGAffineTransform { return A.concatenating(CGAffineTransform(shift: -p)) }
func +(A: CGAffineTransform, q: CGSize) -> CGAffineTransform { return A.concatenating(CGAffineTransform(shift:  q)) }
func -(A: CGAffineTransform, q: CGSize) -> CGAffineTransform { return A.concatenating(CGAffineTransform(shift: -q)) }

func +(p: CGPoint, A: CGAffineTransform) -> CGAffineTransform { return A.translatedBy(x: p.x, y: p.y) }
func +(p: CGSize, A: CGAffineTransform) -> CGAffineTransform { return A.translatedBy(x: p.width, y: p.height) }

// adddition of vectors, commutative
func +(p: CGPoint, q: CGPoint) -> CGPoint { return CGPoint(x: p.x+q.x, y: p.y+q.y) }
func -(p: CGPoint, q: CGPoint) -> CGPoint { return CGPoint(x: p.x-q.x, y: p.y-q.y) }
func +(p: CGPoint, q: CGSize) -> CGPoint { return CGPoint(x: p.x+q.width, y: p.y+q.height) }
func -(p: CGPoint, q: CGSize) -> CGPoint { return CGPoint(x: p.x-q.width, y: p.y-q.height) }
func +(p: CGSize, q: CGSize) -> CGSize { return CGSize(width: p.width+q.width, height: p.height+q.height) }
func -(p: CGSize, q: CGSize) -> CGSize { return CGSize(width: p.width-q.width, height: p.height-q.height) }

// compound assignment operators
func +=(p: inout CGPoint, q: CGPoint) { p.x += q.x; p.y += q.y }
func -=(p: inout CGPoint, q: CGPoint) { p.x -= q.x; p.y -= q.y }
func +=(p: inout CGPoint, q: CGSize) { p.x += q.width; p.y += q.height }
func -=(p: inout CGPoint, q: CGSize) { p.x -= q.width; p.y -= q.height }
func +=(p: inout CGSize, q: CGSize) { p.width += q.width; p.height += q.height }
func -=(p: inout CGSize, q: CGSize) { p.width -= q.width; p.height -= q.height }

// unary operators
prefix func +(p: CGPoint) -> CGPoint { return p }
prefix func +(q: CGSize) -> CGSize  { return q }
prefix func -(p: CGPoint) -> CGPoint { return CGPoint(x: -p.x, y: -p.y) }
prefix func -(q: CGSize) -> CGSize  { return CGSize(width: -q.width, height: -q.height) }
