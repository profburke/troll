//
//  Unary.swift
//  Troll
//
// Copyright (c) 2021 BlueDino Software (https://bluedino.net)
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation and/or
//    other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be
//    used to endorse or promote products derived from this software without specific prior
//    written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
// THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
// OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
// TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Foundation

public class Unary: Expr {
    public let op: Token
    public let operandSchema: UnaryOperandSchema
    public let right: Expr

    public init(op: Token, right: Expr, operandSchema: UnaryOperandSchema) {
        self.op = op
        self.right = right
        self.operandSchema = operandSchema
    }
}

extension Unary {
    public func evaluate(interpreter: Interpreter) throws -> Value {
        let value = try right.evaluate(interpreter: interpreter)
        
        switch operandSchema {
        case .collection:
            return try evaluateCollectionOperand(value, reportError: interpreter.error)
        case .deferOperand:
            return try evaluateDeferOperand(value, reportError: interpreter.error)
        case .double:
            return try evaluateDoubleOperand(value, reportError: interpreter.error)
        case .singleton:
            return try evaluateSingletonOperand(value, reportError: interpreter.error)
        case .tuple:
            return try evaluateTupleOperand(value, reportError: interpreter.error)
        }
    }
    
    private func evaluateCollectionOperand(_ value: Value, reportError: ErrorFunction) throws -> Value {
        guard case .collection(let ints) = value else {
            reportError(op, "Operand must be an integer collection.")
            throw RuntimeError.needsIntCollection
        }
        
        switch op.type {
        case .count:
            return .collection([ints.count])
        case .different:
            let s = Set(ints)
            return .collection(Array(s))
        case .choose:
            guard ints.count > 0 else {
                reportError(op, "Choose requires a non-empty collection for its operand.")
                throw RuntimeError.invalidOperand
            }
            
            guard let selected = ints.randomElement() else {
                fatalError("Operand for choose is empty collection.")
            }
            
            return .collection([selected])
        case .sum:
            let s = ints.reduce(0, +)
            return .collection([s])
        case .min:
            guard ints.count > 0 else {
                reportError(op, "Min cannot be applied to an empty collection.")
                throw RuntimeError.invalidOperand
            }
            
            if let m = ints.min() {
                return .collection([m])
            } else {
                return .collection([])
            }
        case .max:
            guard ints.count > 0 else {
                reportError(op, "Max cannot be applied to an empty collection.")
                throw RuntimeError.invalidOperand
            }
            
            if let m = ints.max() {
                return .collection([m])
            } else {
                return .collection([])
            }
        case .median:
            guard ints.count > 0 else {
                reportError(op, "Median cannot be applied to an empty collection.")
                throw RuntimeError.invalidOperand
            }

            let n = ints.count
            return .collection([ints.sorted()[n/2]])
        case .minimal:
            let m = ints.min()
            let result = ints.compactMap { ($0 == m) ? m : nil }
            return .collection(result)
        case .maximal:
            let m = ints.max()
            let result = ints.compactMap { ($0 == m) ? m : nil }
            return .collection(result)
        case .bang:
            return (ints.count == 0) ? .collection([1]) : .collection([])
        default:
            internalError(token: op)
        }
    }

    private func evaluateDeferOperand(_ value: Value, reportError: ErrorFunction) throws -> Value {
        return .string("\(value)")
    }

    private func evaluateDoubleOperand(_ value: Value, reportError: ErrorFunction) throws -> Value {
        guard let r = value.double, r > 0.0 else {
            reportError(op, "Probabilistic operator requires a real number between 0 and 1 for its operand.")
            throw RuntimeError.needsReal
        }
        
        switch op.type {
        case .question:
            return (Double.random(in: 0..<1) < r) ? .collection([1]) : .collection([])
        default:
            internalError(token: op)
        }
    }
    
    private func evaluateSingletonOperand(_ value: Value, reportError: ErrorFunction) throws -> Value {
        guard let r = value.integer else {
            reportError(op, "Operand must be a single integer.")
            throw RuntimeError.needsSingleton
        }
        
        switch op.type {
        case .die:
            guard r > 0 else {
                reportError(op, "Number of faces must be >0.")
                throw RuntimeError.invalidOperand
            }

            return .collection([Int.random(in: 1...r)])
        case .zeroDie:
            guard r > 0 else {
                reportError(op, "Number of faces must be >0.")
                throw RuntimeError.invalidOperand
            }

            return .collection([Int.random(in: 0...r)])
        case .minus:
            return .collection([-1 * r])
        case .sgn:
            return .collection([r.signum()])
        default:
            internalError(token: op)
        }
    }

    private func evaluateTupleOperand(_ value: Value, reportError: ErrorFunction) throws -> Value {
        guard case let .tuple(expressions) = value else {
            reportError(op, "Operand must be a tuple.")
            throw RuntimeError.needsTuple
        }

        switch op.type {
        case .first:
            guard expressions.count >= 1 else {
                reportError(op, "Tuple has no first element.")
                throw RuntimeError.invalidOperand
            }
            return expressions[0]
        case .second:
            guard expressions.count >= 2 else {
                reportError(op, "Tuple has no second element.")
                throw RuntimeError.invalidOperand
            }
            return expressions[1]
        default:
            internalError(token: op)
        }
    }
}

extension Unary: CustomStringConvertible {
    public var description: String {
        return parenthesize(name: op.lexeme, exprs: right)
    }
}
