//
//  FunctionCall.swift
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

public class FunctionCall: Expr {
    let identifier: String
    let arguments: [Expr]

    public init(identifier: String, arguments: [Expr]) {
        self.identifier = identifier
        self.arguments = arguments
    }

    public func evaluate(interpreter: Interpreter) throws -> Value {
        guard let functionDefinition = interpreter.functionLookup(identifier) else {
            interpreter.error(message: "'\(identifier)' is not a defined function.")
            throw RuntimeError.unknownFunction
        }

        guard arguments.count == functionDefinition.arity else {
            interpreter.error(message: "'\(identifier)' should be called with \(functionDefinition.arity) arguments, received \(arguments.count).")
            throw RuntimeError.incorrectArgumentCount
        }

        // bind arguments to parameters
        for (i, parameter) in functionDefinition.parameters.enumerated() {
            let argument = try arguments[i].evaluate(interpreter: interpreter)
            interpreter.push(Symbol(identifier: parameter, value: argument))
        }

        // evaluate the function body
        let value = try functionDefinition.body.evaluate(interpreter: interpreter)

        // pop the bindings
        (0..<functionDefinition.arity).forEach { _ in
            interpreter.pop()
        }
        
        return value
    }
}

extension FunctionCall: CustomStringConvertible {
    public var description: String {
        return parenthesize(name: "Call: \(identifier)", exprs: arguments)
    }
}
