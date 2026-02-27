//
//  ParserTests.swift
//  TrollTests
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

import Troll
import XCTest

final class ParserTests: XCTestCase {

    // Scans source, calls parse(), returns the ParserError or nil.
    private func parseError(for source: String) -> Parser.ParserError? {
        let scanner = Troll.Scanner(source)
        guard case .success(let tokens) = scanner.scan() else { return nil }
        guard case .failure(let e) = Parser(tokens).parse() else { return nil }
        return e
    }

    // Scans source, calls parseArgs(), returns the ParserError or nil.
    private func parseArgsError(for source: String) -> Parser.ParserError? {
        let scanner = Troll.Scanner(source)
        guard case .success(let tokens) = scanner.scan() else { return nil }
        guard case .failure(let e) = Parser(tokens).parseArgs() else { return nil }
        return e
    }

    // MARK: - invalidRedefinition

    func testInvalidRedefinition() {
        XCTAssertEqual(parseError(for: "function f() = 1 function f() = 2 5"), .invalidRedefinition)
    }

    // MARK: - malformedArgument

    func testMalformedArgument() {
        // "foo" is a bare identifier — not in the expected identifier=integer form
        XCTAssertEqual(parseArgsError(for: "foo"), .malformedArgument)
    }

    // MARK: - missingCondition

    func testMissingConditionRepeat() {
        // Missing 'while'/'until' after the initializer expression
        XCTAssertEqual(parseError(for: "repeat x := 1 2"), .missingCondition)
    }

    func testMissingConditionAccumulate() {
        XCTAssertEqual(parseError(for: "accumulate x := 1 2"), .missingCondition)
    }

    // MARK: - needsVariable

    func testNeedsVariable() {
        // '~' requires a Variable as its left operand, not a literal
        XCTAssertEqual(parseError(for: "1 ~ d6"), .needsVariable)
    }

    // MARK: - unexpectedToken

    func testUnexpectedTokenTrailing() {
        // Extra token after a complete expression — triggers script() L108
        XCTAssertEqual(parseError(for: "1 2"), .unexpectedToken)
    }

    func testUnexpectedTokenBadStart() {
        // ')' cannot start an expression — triggers primary() L494
        XCTAssertEqual(parseError(for: ")"), .unexpectedToken)
    }

    func testUnexpectedTokenMissingExpected() {
        // 'if 1 then 2' has no 'else' — consume(.else) triggers unexpectedToken
        XCTAssertEqual(parseError(for: "if 1 then 2"), .unexpectedToken)
    }
}
