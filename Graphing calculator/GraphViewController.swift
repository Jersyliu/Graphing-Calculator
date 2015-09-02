//
//  GraphViewController.swift
//  Graphing calculator
//
//  Created by Ruslan Serebryakov on 7/16/15.
//  Copyright (c) 2015 Ruslan Serebryakov. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, GraphViewDataSource, UIPopoverPresentationControllerDelegate {
    private var model = CalculatorModel()
    private var cacheData = [CGFloat:CGFloat]()
    
    var statistics: (min: Double?, max: Double?) {
        didSet {
            if oldValue.min != nil {
                if oldValue.min < statistics.min {
                    statistics.min = oldValue.min
                }
            }
            if oldValue.max != nil {
                if oldValue.max > statistics.max {
                    statistics.max = oldValue.max
                }
            }
        }
    }
    
    typealias PropertyList = AnyObject
    var program: PropertyList? {
        didSet {
            model.program = program!
            cacheData = [CGFloat:CGFloat]()
        }
    }
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    var scale: CGFloat {
        get { return defaults.objectForKey("scale") as? CGFloat ?? 50.0 }
        
        set { defaults.setObject(newValue, forKey: "scale") }
    }
    var origin: CGPoint? {
        get {
            if let originPropertyList = defaults.objectForKey("origin") as? [CGFloat] {
                var origin = CGPoint()
                origin.x = originPropertyList.first!
                origin.y = originPropertyList.last!
                return origin
            }
            return nil
        }
        set {
            defaults.setObject([newValue!.x, newValue!.y], forKey: "origin")
        }
    }
    
    @IBOutlet weak var graphViewOutlet: GraphView! {
        didSet {
            graphViewOutlet.dataSource = self
            graphViewOutlet.addGestureRecognizer(UIPinchGestureRecognizer(target: graphViewOutlet, action: "scale:"))
            graphViewOutlet.addGestureRecognizer(UIPanGestureRecognizer(target: graphViewOutlet, action: "move:"))
            let tap = UITapGestureRecognizer(target: graphViewOutlet, action: "setOrigin:")
            tap.numberOfTapsRequired = 2
            graphViewOutlet.addGestureRecognizer(tap)
            graphViewOutlet.scale = scale
            graphViewOutlet.origin = origin
            
            self.title = model.lastOperation
        }
    }
    
    func getY(x: CGFloat) -> CGFloat? {
        if let yCached = cacheData[x] {
            return yCached
        }
        
        model.setVariable("M", value: Double(x))
        let result = model.evaluateStack()
        
        switch result {
        case .Number(let value):
            statistics = (value, value)
            println(statistics)
            cacheData[x] = CGFloat(value)
            return cacheData[x]
        default:break
        }
        return nil
    }
    
    override func viewWillDisappear(animated: Bool) {
        scale = graphViewOutlet.scale
        origin = graphViewOutlet.origin
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
                case "Show Statistics":
                if let svc = segue.destinationViewController as? StatisticsViewController {
                    if let ppc = svc.popoverPresentationController {
                        ppc.delegate = self
                    }
                    svc.statistics = "max value: \(statistics.max == nil ? 0 : statistics.max!)\nmin value: \(statistics.min == nil ? 0 : statistics.min!)"
                }
            default: break
            }
        }
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController!, traitCollection: UITraitCollection!) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
}
