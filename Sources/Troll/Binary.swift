//
//  Binary.swift
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

public class Binary: Expr {
    public let left: Expr
    public let right: Expr
    public let op: Token
    public let operandSchema: BinaryOperandSchema

    public init(left: Expr, op: Token, operandSchema: BinaryOperandSchema, right: Expr) {
        self.left = left
        self.right = right
        self.op = op
        self.operandSchema = operandSchema
    }
}

extension Binary {
    public func evaluate(interpreter: Interpreter) throws -> Value {
        let lval = try left.evaluate(interpreter: interpreter)
        let rval = try right.evaluate(interpreter: interpreter)

        switch operandSchema {
        case .collectionCollection:
            return try evaluateCollectionCollectionOperands(lval, rval, reportError: interpreter.error)
        case .collectionSingleton:
            return try evaluateCollectionSingletonOperands(lval, rval, reportError: interpreter.error)
        case .deferOperand:
            return try evaluateDeferOperand(lval, right, interpreter: interpreter, reportError: interpreter.error)
        case .singletonCollection:
            return try evaluateSingletonCollectionOperands(lval, rval, reportError: interpreter.error)
        case .singletonSingleton:
            return try evaluateSingletonSingletonOperands(lval, rval, reportError: interpreter.error)
        case .stringString:
            return try evaluateStringStringOperands(lval, rval, reportError: interpreter.error)
        }
    }

    private func evaluateCollectionCollectionOperands(_ lval: Value, _ rval: Value, reportError: ErrorFunction) throws -> Value {
        guard case .collection(let lints) = lval else {
            reportError(op, "Left operand must be a collection.")
            throw RuntimeError.needsIntCollection
        }

        guard case .collection(let rints) = rval else {
            reportError(op, "Right operand must be a collection.")
            throw RuntimeError.needsIntCollection
        }

        switch op.type {
        case .and:
            return (lints.count == 0) ? .collection([]) : .collection(rints)
        case .drop:
            let droppers = Set(rints)
            let result = lints.compactMap { droppers.contains($0) ? nil : $0 }
            return .collection(result)
        case .keep:
            let keepers = Set(rints)
            let result = lints.compactMap { keepers.contains($0) ? $0 : nil }
            return .collection(result)
        case .setMinus:
            var result = lints
            rints.forEach { element in
                if let index = result.firstIndex(of: element) {
                    result.remove(at: index)
                }
            }
            return .collection(result)
        case .union:
            return .collection(lints + rints)
        default:
            internalError(token: op)
        }
    }

    private func evaluateCollectionSingletonOperands(_ lval: Value, _ rval: Value, reportError: ErrorFunction) throws -> Value {
        guard let lints = lval.collection else {
            reportError(op, "Left operand must be a collection.")
            throw RuntimeError.needsIntCollection
        }

        guard let r = rval.integer else {
            reportError(op, "Right operand must be a single integer value.")
            throw RuntimeError.needsSingleton
        }

        switch op.type {
        case .pick:
            var result: [Int] = []
            var candidates = lints
            if r >= candidates.count {
                result = candidates
            } else {
                for _ in 0..<r {
                    let index = Int.random(in: 0..<candidates.count)
                    result.append(candidates[index])
                    candidates.remove(at: index)
                }
            }
            return .collection(result)
        default:
            internalError(token: op)
        }
    }

    private func doDeferredExpression(count: Int, expr: Expr, interpreter: Interpreter) throws ->  [[Int]] {
        var result: [[Int]] = []
        for _ in 0..<count {
            let rval = try right.evaluate(interpreter: interpreter)

            guard let rints = rval.collection else {
                interpreter.error(token: op, message: "Repeated expression must evaluate to a collection.")
                throw RuntimeError.nonCollectionValue
            }

            result.append(rints)
        }

        return result
    }

    private func evaluateDeferOperand(_ lval: Value, _ right: Expr, interpreter: Interpreter, reportError: ErrorFunction) throws -> Value {
        guard let l = lval.integer else {
            reportError(op, "Left operand must be a single, non-negative integer value.")
            throw RuntimeError.needsSingleton
        }

        guard l >= 0 else {
            reportError(op, "Left operand must be a single, non-negative integer value.")
            throw RuntimeError.invalidOperand
        }

        switch op.type {
        case .sample:
            let rints = try doDeferredExpression(count: l, expr: right, interpreter: interpreter)
            let lines = rints.map { "\(Value.collection($0))" }
            let result = (lines.count == 0) ? "" : lines[1...].reduce(lines[0]) { doVconcr($0, $1) }

            return .string(result)
        case .hash:
            let rints = try doDeferredExpression(count: l, expr: right, interpreter: interpreter)

            return .collection(rints.flatMap { $0 })
        default:
            internalError(token: op)
        }
    }

    private func evaluateSingletonCollectionOperands(_ lval: Value, _ rval: Value, reportError: ErrorFunction) throws -> Value {
        guard let l = lval.integer else {
            reportError(op, "Left operand must be a single integer value.")
            throw RuntimeError.needsSingleton
        }

        guard let rints = rval.collection else {
            reportError(op, "Right operand must be a collection.")
            throw RuntimeError.needsIntCollection
        }

        switch op.type {
        case .eq:
            let result = rints.compactMap { (l == $0) ? $0: nil }
            return .collection(result)
        case .neq:
            let result = rints.compactMap { (l != $0) ? $0: nil }
            return .collection(result)
        case .lt:
            let result = rints.compactMap { (l < $0) ? $0: nil }
            return .collection(result)
        case .gt:
            let result = rints.compactMap { (l > $0) ? $0: nil }
            return .collection(result)
        case .le:
            let result = rints.compactMap { (l <= $0) ? $0: nil }
            return .collection(result)
        case .ge:
            let result = rints.compactMap { (l >= $0) ? $0: nil }
            return .collection(result)
        case .least:
            let upper = min(rints.count, l)
            let result = rints.sorted()[0..<upper]
            return .collection(Array(result))
        case .largest:
            let upper = min(rints.count, l)
            let result = rints.sorted().reversed()[0..<upper]
            return .collection(Array(result))
        default:
            internalError(token: op)
        }
        
    }

    private func evaluateSingletonSingletonOperands(_ lval: Value, _ rval: Value, reportError: ErrorFunction) throws -> Value {
        guard let l = lval.integer else {
            reportError(op, "Left operand must be a single integer value.")
            throw RuntimeError.needsSingleton
        }
        
        guard let r = rval.integer else {
            reportError(op, "Right operand must be a single integer value.")
            throw RuntimeError.needsSingleton
        }
        
        switch op.type {
        case .dotDot:
            return (l <= r) ? .collection(Array(l...r)) : .collection([])
        case .die:
            guard l >= 0 else {
                reportError(op, "Number of die rolled must be non-negative.")
                throw RuntimeError.invalidOperand
            }

            guard r > 0 else {
                reportError(op, "Number of faces must be >0.")
                throw RuntimeError.invalidOperand
            }

            return .collection((0..<l).map { _ in Int.random(in: 1...r)})
        case .zeroDie:
            guard l >= 0 else {
                reportError(op, "Number of die rolled must be non-negative.")
                throw RuntimeError.invalidOperand
            }

            guard r > 0 else {
                reportError(op, "Number of faces must be >0.")
                throw RuntimeError.invalidOperand
            }

            return .collection((0..<l).map { _ in Int.random(in: 0...r)})
        case .plus:
            return .collection([l + r])
        case .minus:
            return .collection([l - r])
        case .times:
            return .collection([l * r])
        case .divide:
            guard r != 0 else {
                reportError(op, "Division by zero.")
                throw RuntimeError.invalidOperand
            }
            return .collection([l / r])
        case .mod:
            guard r != 0 else {
                reportError(op, "Modulo by zero.")
                throw RuntimeError.invalidOperand
            }
            return .collection([l % r])
        default:
            internalError(token: op)
        }
    }

    // To be honest, I only needed to pull out the functionality
    // for vconcr, since I need to use that in two places (.vconcr, and .sample).
    // But I went ahead and pulled all the conc implementations out into separate
    // functions.
    private typealias Padding = (l1: Int, l2: Int, pad: String, pad1: String, pad2: String, padl: String, padr: String)

    private func computePadding(l: String, r: String) -> Padding {
        let l1 = l.lines[0].count
        let l2 = r.lines[0].count
        let l3 = abs(l1 - l2)

        return (l1,
                l2,
                String(repeating: " ", count: l3),
                String(repeating: " ", count: l1),
                String(repeating: " ", count: l2),
                String(repeating: " ", count: l3/2),
                String(repeating: " ", count: l3 - l3/2))

    }

    private func doHconc(_ l: String, _ r: String) -> String {
        let p = computePadding(l: l, r: r)
        let zipped = zip(l.lines, default: p.pad1, r.lines, default: p.pad2)
        let s = zipped.map { $0.0 + $0.1 }

        return s.joined(separator: "\n")
    }

    private func doVconcl(_ l: String, _ r: String) -> String {
        let p = computePadding(l: l, r: r)
        var s: [String]
        if p.l1 == p.l2 {
            s = l.lines + r.lines
        } else if p.l1 < p.l2 {
            s =  l.lines.map { $0 + p.pad } + r.lines
        } else {
            s = l.lines + r.lines.map { $0 + p.pad }
        }

        return s.joined(separator: "\n")
    }

    private func doVconcr(_ l: String, _ r: String) -> String {
        let p = computePadding(l: l, r: r)
        var s: [String]
        if p.l1 == p.l2 {
            s = l.lines + r.lines
        } else if p.l1 < p.l2 {
            s =  l.lines.map { p.pad + $0 } + r.lines
        } else {
            s = l.lines + r.lines.map { p.pad + $0 }
        }

        return s.joined(separator: "\n")
    }

    private func doVconcc(_ l: String, _ r: String) -> String {
        let p = computePadding(l: l, r: r)
        var s: [String]
        if p.l1 == p.l2 {
            s = l.lines + r.lines
        } else if p.l1 < p.l2 {
            s =  l.lines.map { p.padl + $0 + p.padr } + r.lines
        } else {
            s = l.lines + r.lines.map { p.padl + $0 + p.padr }
        }

        return s.joined(separator: "\n")
    }

    private func evaluateStringStringOperands(_ lval: Value, _ rval: Value, reportError: ErrorFunction) throws -> Value {
        guard let l = lval.string else {
            reportError(op, "Left operand must be a string.")
            throw RuntimeError.needsString
        }

        guard let r = rval.string else {
            reportError(op, "Right operand must be a string.")
            throw RuntimeError.needsString
        }

        switch op.type {
        case .hconc:
            return .string(doHconc(l, r))
        case .vconcl:
            return .string(doVconcl(l, r))
        case .vconcr:
            return .string(doVconcr(l, r))
        case .vconcc:
            return .string(doVconcc(l, r))
        default:
            internalError(token: op)
        }
    }    
}

extension Binary: CustomStringConvertible {
    public var description: String {
        return parenthesize(name: op.lexeme, exprs: left, right)
    }
}
