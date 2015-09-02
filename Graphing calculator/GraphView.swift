//
//  GraphModel.swift
//  Graphing calculator
//
//  Created by Ruslan Serebryakov on 7/16/15.
//  Copyright (c) 2015 Ruslan Serebryakov. All rights reserved.
//

import UIKit

protocol GraphViewDataSource: class {
    func getY(x: CGFloat) -> CGFloat?
}

@IBDesignable
class GraphView: UIView {
    var axesDrawer = AxesDrawer(color: UIColor.blueColor())
    
    @IBInspectable
    var scale: CGFloat = 50.0 { didSet { self.setNeedsDisplay() } }
    var origin: CGPoint? { didSet { self.setNeedsDisplay() } }
    @IBInspectable
    var lineWidth: CGFloat = 2.0 { didSet { setNeedsDisplay() } }
    @IBInspectable
    var color: UIColor = UIColor.blackColor() { didSet { setNeedsDisplay() } }
    
    weak var dataSource: GraphViewDataSource?
    
    var graphCenter: CGPoint {
        get {
            return convertPoint(center, fromView: superview)
        }
    }
    
    func scale(sender: UIPinchGestureRecognizer) {
        if sender.state == .Changed {
            scale *= sender.scale
            sender.scale = 1.0
        }
    }
    
    func move(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .Ended: fallthrough
        case .Changed:
            let translation = sender.translationInView(self)
            if translation != CGPointZero {
                origin?.x += translation.x
                origin?.y += translation.y
                sender.setTranslation(CGPointZero, inView: self)
            }
        default: break
        }
    }
    
    func setOrigin(sender: UITapGestureRecognizer) {
        if sender.state == .Ended {
            origin = sender.locationInView(self)
        }
    }
    
    override func drawRect(rect: CGRect) {
        origin = origin ?? graphCenter
        axesDrawer.drawAxesInRect(self.bounds, origin: origin!, pointsPerUnit: scale)
        drawCurveInRect(origin!)
    }
    
    func drawCurveInRect(origin: CGPoint) {
        let curve = UIBezierPath()
        curve.lineWidth = lineWidth
        color.set()
        
        if let startingY = dataSource?.getY(-origin.x / scale) {
            curve.moveToPoint(CGPoint(x:CGFloat(0), y: origin.y - startingY * scale))
        }
        
        var point = CGPoint()
        for var i=0; i<Int(bounds.size.width * contentScaleFactor); i++ {
            point.x = CGFloat(i) / contentScaleFactor
            if let y = dataSource?.getY((point.x - origin.x) / scale) {
                point.y = origin.y - y * scale
                curve.addLineToPoint(point)
                //curve.stroke()
            } else if let y = dataSource?.getY((point.x - origin.x + CGFloat(1.0)) / scale) {
                point.x += CGFloat(1.0)
                point.y = origin.y - y * scale
                curve.moveToPoint(point)
            }
        }
        curve.stroke()
    }
}