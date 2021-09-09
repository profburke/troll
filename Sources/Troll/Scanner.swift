//
//  Scanner.swift
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

public class Scanner {
    public enum ScannerError: Error {
        case malformedToken
        case noSource
        case unexpectedCharacter
        case unterminatedString
    }
    
    private var error: ScannerError? = nil
    private let reporter: ErrorReporter
    private let source: String
    private var tokens: [Token]
    
    private var current: String.Index
    private var start: String.Index
    
    private var line = 1
    private var pos = 0
    
    public init(_ source: String, reporter: ErrorReporter = ConsoleErrorReporter()) {
        self.reporter = reporter
        self.source = source
        tokens = []
        current = source.startIndex
        start = current
    }
    
    public func scan() -> Result<Array<Token>, ScannerError> {
        if source.isEmpty { return .failure(.noSource) }
        
        while !atEnd() {
            start = current
            scanToken()
        }
        
        tokens.append(Token(type: .EOF,
                            lexeme: "",
                            literal: .none,
                            line: line,
                            position: pos))
        
        if let error = error {
            return .failure(error)
        } else {
            return .success(tokens)
        }
    }
    
    private func scanToken() {
        let c = advance()
        
        switch c {
        case "+": addToken(.plus)
        case "*": addToken(.times)
        case "/": addToken(.divide)
        case "(": addToken(.lparen)
        case ")": addToken(.rparen)
        case ",": addToken(.comma)
        case ";": addToken(.semicolon)
        case "{": addToken(.lbrace)
        case "}": addToken(.rbrace)
        case "@": addToken(.union)
        case "&": addToken(.and)
        case "#": addToken(.hash)
        case "?": addToken(.question)
        case "'": addToken(.sample)
        case "[": addToken(.lbrack)
        case "]": addToken(.rbrack)
        case "~": addToken(.tilde)
        case "!": addToken(.bang)
            
        case ":":
            if match("=") {
                addToken(.assign)
            } else {
                error(.malformedToken, line: line, position: pos,
                      message: "':' must be followed by '='; found '\(source[current])'.")
            }
            
        case "-": addToken(match("-") ? .setMinus : .minus)
        case ">": addToken(match("=") ? .ge : .gt)
            
        case "<":
            if match("=") {
                addToken(.le)
            } else if match(">") {
                addToken(.vconcc)
            } else if match("|") {
                addToken(.vconcr)
            } else {
                addToken(.lt)
            }
            
        case "|":
            if match("|") {
                addToken(.hconc)
            } else if match(">") {
                addToken(.vconcl)
            } else {
                error(.malformedToken, line: line, position: pos,
                      message: "'|' must be followed by either '|' or '>'; found '\(source[current])'.")
            }
            
        case "%":
            if match("1") {
                addToken(.first)
            } else if match("2") {
                addToken(.second)
            } else {
                error(.malformedToken, line: line, position: pos,
                      message: "'%' must be followed by either '1' or '2'; found '\(source[current])'.")
            }
            
        case "=":
            if match("/") && match("=") {
                addToken(.neq)
            } else {
                addToken(.eq)
            }
            
        case ".":
            if match(".") {
                addToken(.dotDot)
            } else {
                error(.malformedToken, line: line, position: pos,
                      message: "'.' must be followed by '.'; found '\(source[current])'.")
            }
            
        case "\"": string()
        case "\\": while peek() != "\n" && !atEnd() { advance() } // Comments
        case " ", "\r", "\t": break
        case "\n": line += 1; pos = 0
        case "0": realOrZero()
            
        default:
            if c.isDigit {
                integer()
            } else if c.isLetter {
                identifier()
            } else {
                error(.unexpectedCharacter, line: line, position: pos,
                      message: "Unexpected character: '\(c)'.")
            }
        }
    }
    
    // MARK: - Errors
    
    private func error(_ error: ScannerError, line: Int, position: Int, message: String) {
        self.error = error
        reporter.error(line: line, position: position, message: message)
    }
    
    // MARK: - Long Tokens
    
    private func string() {
        while peek() != "\"" && peek() != "\n" && !atEnd() {
            advance()
        }
        
        if atEnd() || peek() == "\n" {
            error(.unterminatedString, line: line, position: pos, message: "Unterminated string.")
        }
        
        let stringStart = source.index(after: start)
        let value = String(source[stringStart..<current])

        // Now the concatenation operators are allowed inside of strings, so that
        // "something<>wicked<>this way comes" === "something" <> "wicked" <> "this way comes"
        // (although, as per the manual, parenthesis inside a string are NOT grouping constructs,
        // i.e. "(how <> now)||brown cow" === "(how " <> " now)" || "brown cow").
        //
        // It's tempting to do something like pre-process the whole source string before beginning
        // the scanning loop, but that would break the positions recorded with each token, which
        // we're not using now, but soon... YAGNI not withstanding. (Also, this does not record correctly
        // the positions of concatenation operators inside a string.)

        let chunks = value.extractConcatenationOperators()
        chunks.forEach { chunk in
            switch chunk {
            case "<>":
                addToken(.vconcc)
            case "<|":
                addToken(.vconcr)
            case "|>":
                addToken(.vconcl)
            case "||":
                addToken(.hconc)
            default:
                addToken(.string, literal: .string(value: chunk))
            }
        }

        // addToken(.string, literal: .string(value: value))

        advance() // past the closing "
    }
    
    private func identifier() {
        while peek().isLetter { advance() }
        
        let text = source[start..<current]
        if let type = TokenType.for(String(text)) {
            addToken(type)
        } else {
            addToken(.identifier)
        }
    }
    
    private func realOrZero() {
        if peek() == "." {
            advance()
            while peek().isDigit { advance() }
            
            guard let value = Double(source[start..<current]) else {
                fatalError("Scanning real: This can't be happening: line \(line), position \(pos).")
            }
            addToken(.real, literal: .real(value: value))
        } else {
            addToken(.integer, literal: .integer(value: 0))
        }
    }
    
    private func integer() {
        while peek().isDigit { advance() }
        
        guard let value = Int(source[start..<current]) else {
            fatalError("Scanning int: This can't be happening: line \(line), position \(pos).")
        }
        addToken(.integer, literal: .integer(value: value))
    }
    
    // MARK: - Scanning Helpers
    
    private func atEnd() -> Bool {
        return current == source.endIndex
    }
    
    @discardableResult
    private func advance() -> Character {
        let result = source[current]
        source.formIndex(after: &current)
        pos += 1
        
        return result
    }
    
    private func peek() -> Character {
        if atEnd() { return "\0" }
        return source[current]
    }
    
    private func match(_ expected: Character) -> Bool {
        if atEnd() { return false }
        if source[current] != expected { return false }
        
        source.formIndex(after: &current)
        return true
    }
    
    // MARK: - Token Creation
    
    private func addToken(_ type: TokenType) {
        addToken(type, literal: .none)
    }
    
    private func addToken(_ type: TokenType, literal: TokenLiteral) {
        let text = String(source[start..<current])
        tokens.append(Token(type: type,
                            lexeme: text,
                            literal: literal,
                            line: line,
                            position: pos))
    }
}

extension Character {
    public var isDigit: Bool {
        return self.isASCII && self.isNumber
    }
}

