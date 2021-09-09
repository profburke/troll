//
//  Interpreter.swift
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

public enum RuntimeError: Error {
    case incorrectArgumentCount
    case invalidOperand
    case invalidBinaryOperator
    case invalidUnaryOperator
    case needsIntCollection
    case needsPair
    case needsReal
    case needsSingleton
    case needsString
    case nonCollectionValue
    case unknownFunction
    case unknownVariable
}

func internalError(token: Token) -> Never {
    let message =
        """
Trying to evalaute \(token.type) at line \(token.line), position \(token.position) but has
incorrect schema type: 
"""
    fatalError(message)
}

// ugh! better name?
public struct Symbol {
    public let identifier: String
    public let value: Value

    public init(identifier: String, value: Value) {
        self.identifier = identifier
        self.value = value
    }
}

public class Interpreter {
    public let version = "0.5.0" // TODO: can we pull this from git at compile time?

    public var reporter: ErrorReporter
    private var functionDefinitions: [String: FunctionDefinition] = [:]
    private var symbols: [Symbol] = []
    
    public init(reporter: ErrorReporter = ConsoleErrorReporter()) {
        self.reporter = reporter
    }

    public func reset() {
        functionDefinitions = [:]
        symbols = []
    }

    public func evaluate(_ expr: Expr) -> Result<Value, RuntimeError> {
        do {
            let result = try expr.evaluate(interpreter: self)
            return .success(result)
        } catch {
            if let re = error as? RuntimeError {
                return .failure(re)
            } else {
                fatalError("Unexpected error: \(error)")
            }
        }
    }

    // MARK: - Symbols

    public func push(_ symbol: Symbol) {
        symbols.append(symbol)
    }

    public func push(_ newSymbols: [Symbol]) {
        symbols += newSymbols
    }

    public func pop() {
        symbols.removeLast()
    }

    public func remove(_ identifier: String) {
        if let index = symbols.lastIndex(where: { $0.identifier == identifier}) {
            symbols.remove(at: index)
        }
    }

    public func lookup(_ identifier: String) -> Value? {
        for symbol in symbols.reversed() {
            if identifier == symbol.identifier {
                return symbol.value
            }
        }
        return nil
    }

    // MARK: - Function Definitions

    public func add(_ functionDefinition: FunctionDefinition) {
        functionDefinitions[functionDefinition.identifier] = functionDefinition
    }

    public func add(_ functionDefinitions: [String: FunctionDefinition]) {
        functionDefinitions.keys.forEach { identifier in
            if let functionDefinition = functionDefinitions[identifier] {
                add(functionDefinition)
            }
        }
    }

    public func functionLookup(_ identifier: String) -> FunctionDefinition? {
        return functionDefinitions[identifier]
    }

    // MARK: - Error handling (well, reporting...)

    public func error(token: Token, message: String) {
        reporter.error(line: token.line,
                       position: token.position,
                       message: message)
    }

    // TODO: hmm...can we do better than -1? Maybe need to add token to Expr protocol
    //       so that we can always grab it (see errors in Accumulate, Collection, Foreach, etc).
    public func error(message: String) {
        reporter.error(line: -1,
                       position: -1,
                       message: message)
    }
}

public typealias ErrorFunction = (Token, String) -> ()
