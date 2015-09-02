//
//  ViewController.swift
//  Graphing calculator
//
//  Created by Ruslan Serebryakov on 7/16/15.
//  Copyright (c) 2015 Ruslan Serebryakov. All rights reserved.
//

import UIKit
//unary to stack

class CalculatorViewController: UIViewController {
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var helper: UILabel!
    @IBOutlet weak var enterButton: UIButton!
    
    var model = CalculatorModel()
    
    var userIsInTheMiddleOfTypingANumber: Bool = false
    
    var displayValue: Double? {
        get {
            if display.text != nil {
                return NSNumberFormatter().numberFromString(display.text!)?.doubleValue
            }
            return nil
        }
    }
    
    func updateDisplayValue(result: CalculatorModel.EvaluationResult) {
        switch result {
        case .Number(let value):
            display.text = "\(value)"
        case .Failure(let error):
            switch error {
            case .FewArguments:
                display.text = "Error: Few arguments"
                model.cleanAllOps()
            case .UnsetVariable:
                display.text = "Error: Unset variable"
            case .DivisionByZero:
                display.text = "Error: Division by zero"
            case .NegativeNumber:
                display.text = "Error: Negative number for square root"
            case .InvalidArgumentForLogarithm:
                display.text = "Error: Invalid argument for logarithm"
            case .UnknownOp:
                display.text = "Error: Unknown op"
            default:
                break;
            }
        }
        
        if let description = model.description {
            helper.text = description
        } else {
            helper.text = " "
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var destination = segue.destinationViewController as? UIViewController
        if let nvc = destination as? UINavigationController {
            destination = nvc.visibleViewController
        }
        if let gvc = destination as? GraphViewController {
            if let identifier = segue.identifier {
                switch identifier {
                case "Move to graph":
                    gvc.program = model.program
                default:break
                }
            }
        }
    }
    
    @IBAction func appendDigit(sender: UIButton) {
        if let symbol = sender.currentTitle {
            if displayValue != 0 || symbol != "0" {
                if userIsInTheMiddleOfTypingANumber {
                    if (symbol != "." || display.text?.rangeOfString(".")?.startIndex == nil) {
                        display.text = display.text! + symbol
                    }
                } else if symbol != "." {
                    display.text = symbol
                    userIsInTheMiddleOfTypingANumber = true
                }
                enterButton.enabled = true
            }
        }
    }
    
    @IBAction func addDigitToStack() {
        if let value = displayValue {
            model.pushOperand(value)
            display.text = "\(value)"
            userIsInTheMiddleOfTypingANumber = false
            enterButton.enabled = false
        }
    }
    
    @IBAction func addChangeableDigit(sender: UIButton) {
        if let symbol = sender.currentTitle {
            model.performOperation(symbol)
            display.text = symbol
            enterButton.enabled = false
        }
    }
    
    @IBAction func setVariable(sender: UIButton) {
        if let title = sender.currentTitle {
            let symbol = "\(title[title.endIndex.predecessor()])"
            let result = model.setVariable(symbol, value: displayValue)
            updateDisplayValue(result)
        }
    }
    
    @IBAction func changeSign(sender: UIButton) {
        if userIsInTheMiddleOfTypingANumber {
            if let currentDisplayValue = displayValue {
                display.text = "\(currentDisplayValue * -1)"
            }
        } else {
            operateDigits(sender)
        }
    }
    
    @IBAction func operateDigits(sender: UIButton) {
        if let operation = sender.currentTitle {
            if userIsInTheMiddleOfTypingANumber {
                addDigitToStack()
            }
            let result = model.performOperation(operation)
            enterButton.enabled = false
            updateDisplayValue(result)
        }
    }
    
    @IBAction func cleanAll() {
        helper.text = " "
        display.text = " "
        userIsInTheMiddleOfTypingANumber = false
        enterButton.enabled = true
        model.cleanAllOps()
    }
    
    @IBAction func cleanDigit() {
        if userIsInTheMiddleOfTypingANumber {
            if var currentDisplayValue = display.text {
                if count(currentDisplayValue) >= 2 {
                    display.text = dropLast(currentDisplayValue)
                    if currentDisplayValue.hasSuffix(".") {
                        display.text = dropLast(currentDisplayValue)
                    }
                } else {
                    display.text = " "
                    userIsInTheMiddleOfTypingANumber = false
                }
            }
        } else {
            let result = model.cleanOp()
            updateDisplayValue(result)
        }
        
    }
}

