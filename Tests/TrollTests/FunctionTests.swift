//
//  FunctionTests.swift
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

final class FunctionTests: XCTestCase {
    func testCallUnknownFunction() {
        guard let expr = buildAST(for: "call unknown()") else {
            return
        }

        guard case .failure(let reason) = evaluate(expr) else {
            XCTFail("Expected `evaluate` to fail.")
            return
        }
        XCTAssertEqual(reason, .unknownFunction)
    }

    func testCallFunctionWithWrongNumberOfArguments() {
        guard let parsedData = buildASTWithFunctions(for: wrongArgsScript) else {
            return
        }

        guard case .failure(let reason) = evaluateWithFunctions(parsedData) else {
            XCTFail("Expected `evaluate` to fail.")
            return
        }
        XCTAssertEqual(reason, .incorrectArgumentCount)
    }

    func testCallFunction() {
        guard let parsedData = buildASTWithFunctions(for: correctScript) else {
            return
        }

        switch evaluateWithFunctions(parsedData) {
        case .failure(let err):
            XCTFail("Expected 'evaluate' to succeed, instead failed with error: \(err).")
        case .success(let value):
            XCTAssertEqual(value.collection?.count, 5)
        }


    }

    let correctScript = """
function myroll(N, M) = N d M

N := 5; M := 10; call myroll(N, M)
"""

    let wrongArgsScript = """
function funA(N, M) = N d M

call funA(5, 6, 7)
"""
}
