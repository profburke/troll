//
//  Parser.swift
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

public typealias ParsedData = (expression: Expr, functions: [String : FunctionDefinition])

public class Parser {
    public enum ParserError: Error {
        case invalidRedefinition
        case malformedArgument
        case missingCondition
        case needsVariable
        case unexpectedToken
    }

    private var current = 0
    private let tokens: [Token]

    private let reporter: ErrorReporter
    
    public init(_ tokens: [Token], reporter: ErrorReporter = ConsoleErrorReporter()) {
        self.reporter = reporter
        self.tokens = tokens
    }

    public func parseArgs() -> Result<[Symbol], ParserError> {
        var result: [Symbol] = []
        let message = "Arguments must be 'identifier=integer'"

        while !atEnd() {
            do {
                let identifier = try consume(.identifier, message: message)
                try consume(.eq, message: message)
                let intToken = try consume(.integer, message: message)
                guard case .integer(let i) = intToken.literal else {
                    return .failure(.malformedArgument)
                }
                result.append(Symbol(identifier: identifier.lexeme, value: .collection([i])))
            } catch {
                return .failure(.malformedArgument)
            }
        }
        return .success(result)
    }

    public func parse() -> Result<ParsedData, ParserError> {
        do {
            let parsedData = try script()
            return .success(parsedData)
        } catch {
            guard let e = error as? ParserError else {
                fatalError("Received \(error) while parsing.")
            }
            return .failure(e)
        }
    }

    private func script() throws -> (Expr, [String : FunctionDefinition]) {
        var functionDefinitions: [String : FunctionDefinition] = [:]

        while match(.function) {
            let fd = try functionDefinition()
            guard !functionDefinitions.keys.contains(fd.identifier) else {
                error(message: "\(fd.identifier) already defined.")
                throw ParserError.invalidRedefinition
            }

            functionDefinitions[fd.identifier] = fd
        }

        let expr = try expression()

        while match(.function) {
            let fd = try functionDefinition()
            guard !functionDefinitions.keys.contains(fd.identifier) else {
                error(message: "\(fd.identifier) already defined.")
                throw ParserError.invalidRedefinition
            }

            functionDefinitions[fd.identifier] = fd
        }

        if !atEnd() {
            error(message: "Unexpected character at end of script.")
            throw ParserError.unexpectedToken
        }

        return (expr, functionDefinitions)
    }

    private func functionDefinition() throws -> FunctionDefinition {
        let identifier = try consume(.identifier, message: "'Function' keyword must be followed by function name.")
        try consume(.lparen, message: "Function name must be followed by '('.")

        var parameters: [String] = []

        if !match(.rparen) {
            repeat {
                let parameter = try consume(.identifier, message: "Expecting parameter name.")
                parameters.append(parameter.lexeme)
            } while match(.comma)
            try consume(.rparen, message: "Parameters must be followed by ')'.")
        }

        try consume(.eq, message: "Parameter list must be followed by '='.")

        let body = try expression()

        return FunctionDefinition(identifier: identifier.lexeme,
                                  parameters: parameters,
                                  body: body)
    }

    private func expression() throws -> Expr {
        if match(.if) {
            return try ifStatement()
        } else if match(.foreach) {
            return try foreachStatement()
        } else if match(.repeat) {
            return try repeatStatement()
        } else if match(.accumulate) {
            return try accumulateStatement()
        } else if match(.identifier) {
            if peek().type == .assign {
                return try binding()
            } else {
                pushBack()
                return try precedence2()
            }
        } else {
            return try precedence2()
        }
    }

    private func binding() throws -> Expr {
        let identifier = previous().lexeme
        advance() // skip over the ':='
        let definition = try expression()
        try consume(.semicolon, message: "Expected ';' after assignment.")
        let use = try expression()
        
        return Binding(identifier: identifier, definition: definition, use: use)
    }
    
    private func ifStatement() throws -> Expr {
        let cond = try expression()
        try consume(.then, message: "'then' expected after 'if' condition.")
        let trueBranch = try expression()
        try consume(.else, message: "'else' expected after if's true branch.")
        let falseBranch = try expression()

        return If(condition: cond, trueBranch: trueBranch, falseBranch: falseBranch)
    }

    private func foreachStatement() throws -> Expr {
        let identifier = try consume(.identifier, message: "Foreach must be followed by an identifier name.").lexeme
        try consume(.in, message: "Foreach variable must be followed by 'in'.")
        let expr = try expression()
        try consume(.do, message: "Foreach expression must be followed by 'do'.")
        let body = try expression()

        return Foreach(identifier: identifier, expr: expr, body: body)
    }

    private func repeatStatement() throws -> Expr {
        let identifier = try consume(.identifier, message: "Repeat must be followed by an identifier name.").lexeme
        try consume(.assign, message: "Repeat variable must be followed by ':='.")
        let expr = try expression()

        guard match(.until, .while),
              let endStyle = EndStyle(previous().type) else {
            error(message: "Expected either 'while' or 'until'.")
            throw ParserError.missingCondition
        }

        let test = try expression()

        return Repeat(identifier: identifier, expr: expr, endStyle: endStyle, test: test)
    }

    private func accumulateStatement() throws -> Expr {
        let identifier = try consume(.identifier, message: "Accumulate must be followed by an identifier name.").lexeme
        try consume(.assign, message: "Accumulate variable must be followed by ':='.")
        let expr = try expression()

        guard match(.until, .while),
              let endStyle = EndStyle(previous().type) else {
            error(message: "Expected either 'while' or 'until'.")
            throw ParserError.missingCondition
        }

        let test = try expression()

        return Accumulate(identifier: identifier, expr: expr, endStyle: endStyle, test: test)
    }

    /*

     Some of these levels have commonly used names (term, factor). But others don't. In a few
     cases, I can think of reasonable names (multidie, die). The rest I'll just leave as
     precedence<N>.

     */

    private func precedence2() throws -> Expr {
        var expr = try precedence3()

        while match(.vconcl, .vconcr, .vconcc, .hconc) {
            let op = previous()
            let right = try precedence3()
            expr = Binary(left: expr, op: op, operandSchema: .stringString, right: right)
        }

        return expr
    }

    // NOTE: .. isn't associative
    private func precedence3() throws -> Expr {
        var expr = try precedence4()

        if match(.dotDot) {
            let op = previous()
            let right = try precedence4()
            expr = Binary(left: expr, op: op, operandSchema: .singletonSingleton, right: right)
        }
        
        return expr
    }

    private func precedence4() throws -> Expr {
        var expr = try precedence5()

        while match(.drop, .keep, .pick, .setMinus) {
            let op = previous()
            let right = try precedence5()
            let schema: BinaryOperandSchema = (op.type == .pick)
                ? .collectionSingleton
                : .collectionCollection

            expr = Binary(left: expr, op: op, operandSchema: schema, right: right)
        }

        return expr
    }

    private func precedence5() throws -> Expr {
        var expr = try term()

        while match(.union, .and) {
            let op = previous()
            let right = try term()
            expr = Binary(left: expr, op: op, operandSchema: .collectionCollection, right: right)
        }
        
        return expr
    }

    private func term() throws -> Expr {
        var expr = try factor()

        while match(.minus, .plus) {
            let op = previous()
            let right = try factor()
            expr = Binary(left: expr, op: op, operandSchema: .singletonSingleton, right: right)
        }

        return expr
    }

    private func factor() throws -> Expr {
        var expr = try precedence8()

        while match(.divide, .times, .mod) {
            let op = previous()
            let right = try precedence8()
            expr = Binary(left: expr, op: op, operandSchema: .singletonSingleton, right: right)
        }

        return expr
    }

    private func precedence8() throws -> Expr {
        if match(.minus) {
            let op = previous()
            let right = try precedence8()
            return Unary(op: op, right: right, operandSchema: .singleton)
        }
        
        return try precedence9()
    }

    private func precedence9() throws -> Expr {
        if match(.count, .sum, .min, .max, .minimal, .maximal, .median, .choose, .different, .bang, .sgn, .sample) {
            let op = previous()
            let right = try precedence9()
            
            let schema: UnaryOperandSchema
            switch op.type {
            case .sample:
                schema = .deferOperand
            case .sgn:
                schema = .singleton
            default:
                schema = .collection
            }

            return Unary(op: op, right: right, operandSchema: schema)
        }

        // TODO: add .third ... .ninth ??? operators ???
        if match(.first, .second) {
            let op = previous()
            let right = try precedence9()
            return Unary(op: op, right: right, operandSchema: .tuple)
        }
        
        if match(.least, .largest) {
            let op = previous()
            let left = try precedence9()
            let right = try precedence9()
            return Binary(left: left, op: op, operandSchema: .singletonCollection, right: right)
        }

        var expr = try precedence10()

        while match(.sample) {
            let op = previous()
            let right = try precedence9()
            expr = Binary(left: expr, op: op, operandSchema: .deferOperand, right: right)
        }

        return expr
    }

    private func precedence10() throws -> Expr {
        var expr = try multidie()

        while match(.eq, .neq, .lt, .le, .gt, .ge) {
            let op = previous()
            let right = try precedence10()
            expr = Binary(left: expr, op: op, operandSchema: .singletonCollection, right: right)
        }

        return expr
    }

    private func multidie() throws -> Expr {
        var expr = try die()

        while match(.die, .zeroDie, .hash, .tilde) {
            let op = previous()
            let right = try die()

            if op.type == .tilde {
                guard let variable = expr as? Variable else {
                    error(message: "'~' requires a variable as its left-hand operand.")
                    throw ParserError.needsVariable
                }
                expr = Variable(identifier: variable.identifier, default: right)
            } else {
                let schema: BinaryOperandSchema = (op.type == .hash) ? .deferOperand : .singletonSingleton
                expr = Binary(left: expr, op: op, operandSchema: schema, right: right)
            }
        }

        return expr
    }

    private func die() throws -> Expr {
        if match(.die, .zeroDie) {
            let op = previous()
            let right = try die()
            return Unary(op: op, right: right, operandSchema: .singleton)
        }
        
        return try primary()
    }

    private func primary() throws -> Expr {
        if match(.question) {
            let op = previous()
            let real = try consume(.real,
                                   message: "'?' must be followed by a real number between 0 and 1.")
            if case .real(let value) = real.literal {
                return Unary(op: op, right: Literal(value: .double(value)), operandSchema: .double)
            } else {
                fatalError("Real token without real value! Line: \(peek().line), pos: \(peek().position).")
            }
        }

        // TODO: does function call belong in primary?
        if match(.call) {
            let identifier = try consume(.identifier, message: "Function name must follow 'call'.")
            var arguments: [Expr] = []

            try consume(.lparen, message: "Function name must be followed by '('.")
            if !match(.rparen) {
                repeat {
                    let argument = try expression()
                    arguments.append(argument)
                } while match(.comma)
                try consume(.rparen, message: "Arguments must be followed by ')'.")
            }

            return FunctionCall(identifier: identifier.lexeme, arguments: arguments)
        }

        if match(.identifier) {
            return Variable(identifier: previous().lexeme)
        }
        
        if match(.string) {
            if case .string(let value) = previous().literal {
                return Literal(value: .string(value))
            } else {
                // shouldn't be able to get here
                fatalError("problem parsing a string literal")
            }
        }
        
        if match(.integer) {
            if case .integer(let value) = previous().literal {
                return Literal(value: .collection([value]))
            } else {
                // shouldn't be able to get here
                fatalError("problem parsing an integer literal")
            }
        }

        if match(.lparen) {
            let expr = try expression()
            try consume(.rparen, message: "Expect ')' after expression.")
            
            return Group(expr: expr)
        }

        // TODO: can we combine next two sections? (conditional on .lbrace, .lbrack?)
        // TODO: error messages for no comma following expr?

        if match(.lbrace) {
            var exprs: [Expr] = []

            if peek().type != .rbrace {
                repeat {
                    let expr = try expression()
                    exprs.append(expr)
                } while match(.comma);
            }
            
            try consume(.rbrace, message: "Expect '}' after expression collection.")

            return Collection(exprs: exprs)
        }

        if match(.lbrack) {
            var exprs: [Expr] = []

            if peek().type != .rbrack {
                repeat {
                    let expr = try expression()
                    exprs.append(expr)
                } while match(.comma);
            }

            try consume(.rbrack, message: "Expect ']' after tuple.")

            return Tuple(expressions: exprs)
        }

        error(message: "Unexpected characters when parsing literal expression.")
        throw ParserError.unexpectedToken
    }
    
    // MARK: - Parsing Helpers

    private func match(_ types: TokenType...) -> Bool {
        for type in types {
            if check(type) {
                advance()
                return true
            }
        }

        return false
    }

    @discardableResult
    private func consume(_ type: TokenType, message: String) throws -> Token {
        if check(type) {
            return advance()
        }

        error(message: message)
        throw ParserError.unexpectedToken
    }
    
    private func check(_ type: TokenType) -> Bool {
        if atEnd() {
            return false
        }

        return peek().type == type
    }

    @discardableResult
    private func advance() -> Token {
        if !atEnd() {
            current += 1
        }

        return previous()
    }
    
    private func atEnd() -> Bool {
        return peek().type == .EOF
    }

    private func peek() -> Token {
        return tokens[current]
    }

    private func previous() -> Token {
        return tokens[current - 1]
    }

    private func pushBack() {
        current = max(0, current - 1)
    }

    private func error(message: String) {
        reporter.error(line: peek().line,
                       position: peek().position,
                       message: message)
    }
}
