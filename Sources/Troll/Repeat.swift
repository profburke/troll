//
//  Repeat.swift
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

public class Repeat: Expr {
    public let identifier: String
    public let expr: Expr
    public let endStyle: EndStyle
    public let test: Expr

    public init(identifier: String, expr: Expr, endStyle: EndStyle, test: Expr) {
        self.identifier = identifier
        self.expr = expr
        self.endStyle = endStyle
        self.test = test
    }

    public func evaluate(interpreter: Interpreter) throws -> Value {
        var value: Value = .collection([])

        repetition: while true {
            value = try expr.evaluate(interpreter: interpreter)
            let symbol = Symbol(identifier: identifier, value: value)
            interpreter.push(symbol)

            let testValue = try test.evaluate(interpreter: interpreter)
            guard let _ = testValue.collection else {
                interpreter.error(message: "Test condition for repeat statement should return a collection; instead recieved \(value)")
                throw RuntimeError.needsIntCollection
            }

            switch endStyle {
            case .until:
                if testValue.isTruthy {
                    break repetition
                }
            case .while:
                if testValue.isFalsey {
                    break repetition
                }
            }

            interpreter.pop()
        }

        interpreter.pop()
        return value
    }
}

extension Repeat: CustomStringConvertible {
    public var description: String {
        return "<Repeat \(identifier) := \(expr) \(endStyle.rawValue) \(test)>"
    }
}
