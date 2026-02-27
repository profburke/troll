//
//  ProbabilisticChoiceTests.swift
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

final class ProbabilisticChoiceTests: XCTestCase {
    // NOTE: Scanning and parsing ensure '?' is followed by 0.dd...d.
    //       So we just need to test that an error is thrown for '?0.0'.
    func testPCOperatorMustBeFollowedByARealInOpenRange0To1() {
        [
            "?0.0",
        ]
        .forEach { script in
            guard let expr = buildAST(for: script) else {
                return
            }

            switch evaluate(expr) {
            case .failure(let err):
                XCTAssertEqual(err, RuntimeError.needsReal, "Expected a 'needs Real' error; received: \(err).")
            case .success:
                XCTFail("PC operator must be followed by a real number in the range (0, 1).")
            }
        }
    }

    func testPCOperatorRejectsUpperBound() {
        // ?1.0 cannot be written in source (the scanner only accepts 0.xxx reals),
        // so we construct the AST node directly to exercise the runtime guard.
        let op = Token(type: .question, lexeme: "?", literal: .none, line: 0, position: 0)
        let expr = Unary(op: op, right: Literal(value: .double(1.0)), operandSchema: .double)
        guard case .failure(let err) = evaluate(expr) else {
            XCTFail("?1.0 should fail — upper bound of the open interval must be rejected.")
            return
        }
        XCTAssertEqual(err, .needsReal)
    }

    func testPCOperatorReturnsEitherSingletonOneOrEmptyCollection() {
        (0..<1000).forEach { _ in
            // NOTE: The probabilistic choice operator requires its argument to
            // be in the open range (0, 1). And I thought this would work:
            //
            // let r = Double.random(in: Double.leastNonzeroMagnitude..<1.0)
            //
            // Unfortunately, occassionally a result like  r = "8.27606924929114e-05"
            // would turn up and the scanner choked on it since it's expecting the argument
            // to be 0.dddd...d
            var r = Double.random(in: 0.0..<1.0)
            while (r == 0.0) {
                r = Double.random(in: Double.leastNonzeroMagnitude..<1.0)
            }
            guard let expr = buildAST(for: "?\(r)") else {
                print("Here's the troublesome value: \(r)")
                return
            }

            switch evaluate(expr) {
            case .failure(let err):
                XCTFail("Evaluation yielded: \(err).")
            case .success(let value):
                if !(value == .collection([]) || value == .collection([1])) {
                    XCTFail("PC operator should only return: singleton 1 or empty collection; received: \(value).")
                }
            }
        }
    }
}
