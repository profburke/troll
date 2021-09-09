//
//  TestHelpers.swift
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

import Foundation
import Troll
import XCTest

enum DieType: String {
    case d
    case z
}

struct TestCase {
    let expr: String
    let expected: Value

    init(_ expr: String, _ expected: Value) {
        self.expr = expr
        self.expected = expected
    }
}

func check(_ testCase: TestCase) {
    guard let expr = buildAST(for: testCase.expr) else {
        return
    }

    switch evaluate(expr) {
    case .failure(let err):
        XCTFail("Expected 'evaluate' to succeed, instead failed with error: \(err).")
    case .success(let value):
        XCTAssertEqual(value, testCase.expected)
    }
}

func evaluate(_ expr: Expr) -> Result<Value, RuntimeError> {
    let interpreter = Interpreter(reporter: CircularFileErrorRerporter())
    return interpreter.evaluate(expr)
}

func buildAST(for source: String) -> Expr? {
    let scanner = Scanner(source)
    guard case let .success(tokens) = scanner.scan() else {
        XCTFail("Problem scanning \(source).")
        return nil
    }

    let parser = Parser(tokens)
    guard case .success(let parsedData) = parser.parse() else {
        XCTFail("Problem parsing \(source).")
        return nil
    }

    return parsedData.expression
}

// Yes, double-ugh! But I had written 30-odd tests before I got around to
// needing the parsed functions.  At some point, I'll come back and clean this
// up.

func evaluateWithFunctions(_ parsedData: ParsedData) -> Result<Value, RuntimeError> {
    let interpreter = Interpreter(reporter: CircularFileErrorRerporter())
    interpreter.add(parsedData.functions)
    return interpreter.evaluate(parsedData.expression)
}

func buildASTWithFunctions(for source: String) -> ParsedData? {
    let scanner = Scanner(source)
    guard case let .success(tokens) = scanner.scan() else {
        XCTFail("Problem scanning \(source).")
        return nil
    }

    let parser = Parser(tokens)
    guard case .success(let parsedData) = parser.parse() else {
        XCTFail("Problem parsing \(source).")
        return nil
    }

    return parsedData
}
