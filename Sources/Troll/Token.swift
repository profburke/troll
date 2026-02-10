//
//  Token.swift
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

public enum TokenType: CaseIterable {
    // Single-character tokens
    case die
    case zeroDie
    case union
    case plus
    case times
    case divide
    case lparen
    case rparen
    case comma
    case semicolon
    case lbrace
    case rbrace
    case tilde
    case bang
    case and
    case hash
    case question
    case sample
    case lbrack
    case rbrack
    
    // One or two character tokens
    case minus
    case setMinus
    case assign
    case eq
    case neq
    case lt
    case gt
    case le
    case ge
    case dotDot
    case hconc
    case vconcl
    case vconcr
    case vconcc
    case first
    case second
    
    // Literals
    case integer
    case real
    case identifier
    case string
    
    // Keywords
    case sum
    case sgn
    case mod
    case least
    case largest
    case count
    case drop
    case keep
    case pick
    case median
    case `in`
    case `repeat`
    case accumulate
    case `while`
    case until
    case foreach
    case `do`
    case `if`
    case then
    case `else`
    case min
    case max
    case minimal
    case maximal
    case choose
    case different
    case function
    case call
    case compositional
    
    // End of File
    case EOF
    
    public static func `for`(_ key: String) -> TokenType? {
        return keywords[key]
    }
    
    private static let keywords: [String : TokenType] = [
        "d": .die,
        "D": .die,
        "z": .zeroDie,
        "Z": .zeroDie,
        "U": .union,
        "sum": .sum,
        "sgn": .sgn,
        "mod": .mod,
        "least": .least,
        "largest": .largest,
        "count": .count,
        "drop": .drop,
        "keep": .keep,
        "pick": .pick,
        "median": .median,
        "in": .in,
        "repeat": .repeat,
        "accumulate": .accumulate,
        "while": .while,
        "until": .until,
        "foreach": .foreach,
        "do": .do,
        "if": .if,
        "then": .then,
        "else": .else,
        "min": .min,
        "max": .max,
        "minimal": .minimal,
        "maximal": .maximal,
        "choose": .choose,
        "different": .different,
        "function": .function,
        "call": .call,
        "compositional": .compositional,
    ]
    
}

public enum TokenLiteral {
    case none
    case integer(value: Int)
    case real(value: Double)
    case string(value: String)
}

public struct Token {
    public let type: TokenType
    public let lexeme: String
    public let literal: TokenLiteral
    public let line: Int
    public let position: Int
    
    public init(type: TokenType, lexeme: String, literal: TokenLiteral, line: Int, position: Int) {
        self.type = type
        self.lexeme = lexeme
        self.literal = literal
        self.line = line
        self.position = position
    }
}

extension TokenLiteral: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "--"
        case .integer(let value):
            return "\(value)"
        case .real(let value):
            return "\(value)"
        case .string(let value):
            return value
        }
    }
}

extension Token: CustomStringConvertible {
    public var description: String {
        switch type {
        case .identifier:
            return "<\(type): \(lexeme)>"
        case .integer, .real, .string:
            return "<\(literal)>"
        default:
            return "<\(type)>"
        }
    }
}
