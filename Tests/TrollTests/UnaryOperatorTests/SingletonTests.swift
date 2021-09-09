//
//  SingletonTests.swift
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

final class SingletonTests: XCTestCase {
    func testShouldFailIfOperandNotASingleton() {
        guard let expr = buildAST(for: "sgn {4, 5, 6}") else {
            return
        }

        guard case .failure(let reason) = evaluate(expr) else {
            XCTFail("Expected `evaluate` to fail.")
            return
        }
        XCTAssertEqual(reason, .needsSingleton)
    }

    func testShouldFailForDieWithLessThanOneFace() {
        [
            "d0",
            "Z(-3)",
        ]
        .forEach { testCase in
            guard let expr = buildAST(for: testCase) else {
                return
            }

            switch evaluate(expr) {
            case .failure(let err):
                XCTAssertEqual(err, RuntimeError.invalidOperand, "Die with fewer than one face should trigger an invalid operand error, instead received: \(err).")
            case .success:
                XCTFail("`evalute` should have returned a failure.")
            }
        }
    }

    func testNondeterministicOperators() {
        [
            (bound: 12, type: DieType.d),
            (bound: 12, type: DieType.z),
        ]
        .forEach { testCase in
            let roll = "\(testCase.type)\(testCase.bound)"
            guard let expr = buildAST(for: roll) else {
                return
            }

            (0..<1000).forEach { _ in
                switch evaluate(expr) {
                case .failure(let err):
                    XCTFail("Unexpected error: \(err).")
                case .success(let value):
                    let lower = (testCase.type == .d) ? 1 : 0
                    guard let v = value.integer else {
                        XCTFail("Die roll should have returned singleton, instead returned \(value).")
                        return
                    }
                    if lower > v || v > testCase.bound {
                        XCTFail("\(roll) returned \(v) which is not in the correct range.")
                    }
                }
            }
        }
    }
    
    func testDeterministicOperators() {
        [
            TestCase("- {1}", .collection([-1])),
            TestCase("- {-51}", .collection([51])),
            TestCase("- -12", .collection([12])),
            TestCase("sgn 7", .collection([1])),
            TestCase("sgn(-4)", .collection([-1])),
            TestCase("sgn {-4}", .collection([-1])),
            TestCase("sgn 0", .collection([0])),
        ]
        .forEach { testCase in
            check(testCase)
        }

    }
}
