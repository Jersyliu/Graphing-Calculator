//
//  CalculatorBrain.swift
//  Graphing calculator
//
//  Created by Ruslan Serebryakov on 7/16/15.
//  Copyright (c) 2015 Ruslan Serebryakov. All rights reserved.
//

import Foundation

class CalculatorModel {
    var description: String? {
        get {
            func getHistory(opStack: [Op]) -> String? {
                var resultsStack = [String]()
                var opStackChangeable = opStack
                while opStackChangeable.count > 0 {
                    let (result, priority, remainingOps) = printStack(opStackChangeable)
                    if let value = result {
                        if priority > 0 {
                            resultsStack.append(value)
                        }
                    } else {
                        return nil
                    }
                    opStackChangeable = remainingOps
                }
                if resultsStack.count > 0 {
                    return ", ".join(resultsStack.reverse())
                }
                return nil
            }
            return getHistory(opStack)
        }
    }
    
    var lastOperation: String? {
        get {
            let (result, _, _) = printStack(opStack)
            return result
        }
    }
    
    typealias PropertyList = AnyObject
    var program: PropertyList {
        get {
            return opStack.map({ $0.description })
        }
        set {
            if let opSymbols = newValue as? Array<String> {
                var newOpStack = [Op]()
                for opSymbol in opSymbols {
                    if let op = knownOps[opSymbol] {
                        newOpStack.append(op)
                    } else if let operand = NSNumberFormatter().numberFromString(opSymbol)?.doubleValue {
                        newOpStack.append(.Operand(operand))
                    }
                }
                opStack = newOpStack
            }
            
        }
    }
    
    private enum Op: Printable {
        case Operand(Double)
        case VariableOperand(String, String -> Error?)
        case ConstantOperation(String, Double)
        case UnaryOperation(String, Double -> Double, (Double -> Error?)?)
        case BinaryOperation(String, (Double, Double) -> Double, Int, Bool, (Double -> Error?)?)
        
        var description: String {
            get {
                switch self {
                case .Operand(let value):
                    return "\(value)"
                case .VariableOperand(let symbol, _):
                    return symbol
                case .ConstantOperation(let symbol, _):
                    return symbol
                case .UnaryOperation(let symbol, _, _):
                    return symbol
                case .BinaryOperation(let symbol, _, _, _, _):
                    return symbol
                }
            }
        }
        
        var precedence: Int {
            switch self {
            case .BinaryOperation(_, _, let precendence, _, _):
                return precendence
            case .UnaryOperation(_, _, _):
                return 1
            default:
                return 0
            }
        }
        
        var commutative: Bool {
            switch self {
            case .BinaryOperation(_, _, _, let commutative, _):
                return commutative
            default:
                return true
            }
        }
    }
    
    enum EvaluationResult {
        case Number(Double)
        case Failure(Error)
    }
    
    enum Error {
        case FewArguments
        case UnsetVariable
        case DivisionByZero
        case NegativeNumber
        case InvalidArgumentForLogarithm
        case UnknownOp
    }
    
    private var opStack = [Op]()
    private var knownOps = [String:Op]()
    private var variableOperands = [String:Double]()
    
    init() {
        func learnOperation(operation: Op) {
            knownOps[operation.description] = operation
        }
        
        learnOperation(Op.BinaryOperation("x", { $1 * $0 }, 3, true, nil))
        learnOperation(Op.BinaryOperation("/", { $1 / $0 }, 3, false) { ($0 == 0) ? Error.DivisionByZero : nil })
        learnOperation(Op.BinaryOperation("+", +, 2, true, nil))
        learnOperation(Op.BinaryOperation("-", { $1 - $0 }, 2, false, nil))
        learnOperation(Op.UnaryOperation("✓", sqrt) { ($0 < 0) ? Error.NegativeNumber : nil })
        learnOperation(Op.UnaryOperation("sin", sin, nil))
        learnOperation(Op.UnaryOperation("cos", cos, nil))
        learnOperation(Op.UnaryOperation("log", log) { ($0 <= 0) ? Error.InvalidArgumentForLogarithm : nil })
        learnOperation(Op.UnaryOperation("cot", { 1 / tan($0) }) { ($0 == 0) ? Error.DivisionByZero : nil })
        learnOperation(Op.UnaryOperation("±", { $0 * -1 }, nil))
        learnOperation(Op.ConstantOperation("π", M_PI))
        learnOperation(Op.ConstantOperation("e", M_E))
        learnOperation(Op.VariableOperand("M") { (self.variableOperands[$0] == nil) ? Error.UnsetVariable : nil })
    }
    
    func pushOperand(operand: Double) -> EvaluationResult {
        opStack.append(Op.Operand(operand))
        return evaluateStack()
    }
    
    func pushOperand(symbol: String) -> EvaluationResult {
        if let variableOperand = knownOps[symbol] {
            opStack.append(variableOperand)
            return evaluateStack()
        }
        return EvaluationResult.Failure(Error.UnknownOp)
    }
    
    func setVariable(symbol: String, value: Double?) -> EvaluationResult {
        variableOperands[symbol] = value
        return evaluateStack()
    }
    
    func performOperation(symbol: String) -> EvaluationResult {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
            return evaluateStack()
        }
        return EvaluationResult.Failure(Error.UnknownOp)
    }
    
    func cleanOp() -> EvaluationResult {
        if !opStack.isEmpty {
            opStack.removeLast()
        }
        return evaluateStack()
    }
    
    func cleanAllOps() {
        opStack.removeAll(keepCapacity: false)
        variableOperands.removeAll(keepCapacity: false)
    }
    
    func evaluateStack() -> EvaluationResult {
        let (result, _) = evaluateStack(opStack)
        return result
    }
    
    private func evaluateStack(ops: [Op]) -> (result: EvaluationResult, remainingOps: [Op]) {
        if !ops.isEmpty {
            var remainingOps = ops
            let currentOp = remainingOps.removeLast()
            switch currentOp {
            case .Operand(let value):
                return (EvaluationResult.Number(value), remainingOps)
            case .VariableOperand(let symbol, let errorCheck):
                if let error = errorCheck(symbol) {
                    return (EvaluationResult.Failure(error), remainingOps)
                } else {
                    return (EvaluationResult.Number(variableOperands[symbol]!), remainingOps)
                }
            case .ConstantOperation(_, let constant):
                return (EvaluationResult.Number(constant), remainingOps)
            case .UnaryOperation(_, let operation, let errorCheck):
                let operandEvaluation = evaluateStack(remainingOps)
                switch operandEvaluation.result {
                case .Number(let value):
                    if let error = errorCheck?(value) {
                        return (EvaluationResult.Failure(error), operandEvaluation.remainingOps)
                    } else {
                        return (EvaluationResult.Number(operation(value)), operandEvaluation.remainingOps)
                    }
                case .Failure(let error):
                    return (EvaluationResult.Failure(error), operandEvaluation.remainingOps)
                }
            case .BinaryOperation(_, let operation, _, _, let errorCheck):
                let operand1Evaluation = evaluateStack(remainingOps)
                switch operand1Evaluation.result {
                case .Number(let operand1Value):
                    let operand2Evaluation = evaluateStack(operand1Evaluation.remainingOps)
                    
                    switch operand2Evaluation.result {
                    case .Number(let operand2Value):
                        if let error = errorCheck?(operand1Value) {
                            return (EvaluationResult.Failure(error), operand2Evaluation.remainingOps)
                        } else {
                            return (EvaluationResult.Number(operation(operand1Value, operand2Value)), operand2Evaluation.remainingOps)
                        }
                    case .Failure(let error):
                        return (EvaluationResult.Failure(error), operand2Evaluation.remainingOps)
                    }
                case .Failure(let error):
                    return (EvaluationResult.Failure(error), operand1Evaluation.remainingOps)
                }
            }
        }
        return (EvaluationResult.Failure(Error.FewArguments), ops)
    }
    
    private func printStack(ops: [Op]) -> (result: String?, precedence: Int, remainingOps: [Op]) {
        if !ops.isEmpty {
            var remainingOps = ops
            let currentOp = remainingOps.removeLast()
            switch currentOp {
            case .Operand(let value):
                return ("\(value)", currentOp.precedence, remainingOps)
            case .VariableOperand(let symbol, _):
                return (symbol, currentOp.precedence, remainingOps)
            case .ConstantOperation(let symbol, _):
                return (symbol, currentOp.precedence, remainingOps)
            case .UnaryOperation(let symbol, _, _):
                let operandPrinting = printStack(remainingOps)
                if let operand = operandPrinting.result {
                    return (currentOp.description + "(" + operand + ")", currentOp.precedence, operandPrinting.remainingOps)
                }
            case .BinaryOperation(let symbol, _, _, _, _):
                let operand1Printing = printStack(remainingOps)
                if let operand1 = operand1Printing.result {
                    let operand2Printing = printStack(operand1Printing.remainingOps)
                    if let operand2 = operand2Printing.result {
                        let printOperand1 = ((currentOp.precedence > operand1Printing.precedence && operand1Printing.precedence > 1) || (currentOp.precedence == operand1Printing.precedence && !currentOp.commutative)) ? "(" + operand1 + ")" : operand1
                        let printOperand2 = (currentOp.precedence > operand2Printing.precedence && operand2Printing.precedence > 1) ? "(" + operand2 + ")" : operand2
                        return (printOperand2 + " " + symbol + " " + printOperand1, currentOp.precedence, operand2Printing.remainingOps)
                    }
                }
            default:
                break
            }
        }
        return (nil, 0, ops)
    }
}