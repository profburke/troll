//
//  CollectionTests.swift
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

final class CollectionTests: XCTestCase {
    func testShouldFailIfOperandNotACollection() {
        guard let expr = buildAST(for: "max \"string\"") else {
            return
        }

        guard case .failure(let reason) = evaluate(expr) else {
            XCTFail("Expected `evaluate` to fail.")
            return
        }
        XCTAssertEqual(reason, .needsIntCollection)
    }

    func testMinMaxMedianThrowErrorOnEmptyCollection() {
        [
            "median {}",
            "min {}",
            "max {}",
        ]
        .forEach { script in
            guard let expr = buildAST(for: script) else {
                return
            }

            switch evaluate(expr) {
            case .failure(let err):
                XCTAssertEqual(err, RuntimeError.invalidOperand, "Expected an invalid operand error; received: \(err).")
            case .success:
                XCTFail("Expression should have generated an invalid expression error.")
            }
        }
    }

    func testChooseThrowsErrorOnEmptyCollection() {
        guard let expr = buildAST(for: "choose {}") else {
            return
        }

        switch evaluate(expr) {
        case .failure(let err):
            XCTAssertEqual(err, RuntimeError.invalidOperand, "Expected an invalid operand error; received: \(err).")
        case .success:
            XCTFail("'choose {}' should have thrown an error.")
        }
    }

    func testChooseOperator() {
        guard let expr = buildAST(for: "choose (1..10)") else {
            return
        }

        (0..<1000).forEach { _ in
            switch evaluate(expr) {
            case .failure(let err):
                XCTFail("Should have succeeded; instead received: \(err).")
            case .success(let value):
                guard let i = value.integer else {
                    XCTFail("Should have returned a singleon. Instead received: \(value).")
                    return
                }
                if i < 1 || i > 10 {
                    XCTFail("Returned value not in collection.")
                }
            }
        }
    }
    
    func testDeterministicOperators() {
        [
            TestCase("count {1, 2, 3, 4}", .collection([4])),
            TestCase("count {1, 2, 2, 2}", .collection([4])),
            TestCase("different {1, 2, 3, 4}", .collection([1, 2, 3, 4])),
            TestCase("different {1, 2, 2, 4}", .collection([1, 2, 4])),
            TestCase("different {1, 1, 1, 1}", .collection([1])),
            TestCase("different {1, 1, 10, 10}", .collection([1, 10])),
            TestCase("sum {1, 1, 10, 10}", .collection([22])),
            TestCase("sum {1, 4, 9, 16}", .collection([30])),
            TestCase("min {1, 4, 9, 16}", .collection([1])),
            TestCase("min {1, 4, 9, -16}", .collection([-16])),
            TestCase("max {1, 4, 9, 16}", .collection([16])),
            TestCase("max {10, 4, 9, -16}", .collection([10])),
            TestCase("median {1, 4, 9}", .collection([4])),
            TestCase("median {1, 2, 3, 4}", .collection([3])),
            TestCase("median {2, 2, 2, 4}", .collection([2])),
            TestCase("! {2, 20, -22, 4}", .collection([])),
            TestCase("! {}", .collection([1])),
            TestCase("minimal {1, 2, 3, 4}", .collection([1])),
            TestCase("minimal {1, 2, 1, 4}", .collection([1, 1])),
            TestCase("minimal {}", .collection([])),
            TestCase("maximal {1, 2, 3, 4}", .collection([4])),
            TestCase("maximal {1, 4, 1, 4}", .collection([4, 4])),
            TestCase("maximal {}", .collection([])),
        ]
        .forEach { testCase in
            check(testCase)
        }
    }

}
