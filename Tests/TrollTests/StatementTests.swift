//
//  StatementTests.swift
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

final class StatementTests: XCTestCase {
    func testIfStatement() {
        [
            TestCase("if {1, 2, 3} then 4 else 5", .collection([4])),
            TestCase("if {} then 6 else 7", .collection([7])),
            TestCase("if {8} then \"some\" else [9, 10]", .string("some")),
            TestCase("if {} then \"thing\" else [11, 12]", .pair(.collection([11]), .collection([12]))),
        ]
        .forEach { testCase in
            check(testCase)
        }
    }

    func testForeachStatement() {
        [
            TestCase("foreach x in {1, 2, 3} do x*x", .collection([1, 4, 9])),
        ]
        .forEach { testCase in
            check(testCase)
        }
    }

    func testAccumulateStatement() {
        let test1 = "accumulate x:= d10 until x=10"
        let test2 = "accumulate x:= d10 while x=10"

        guard let expr = buildAST(for: test1) else {
            return
        }

        switch evaluate(expr) {
        case .failure(let err):
            XCTFail("Expression should have succeeded, instead received: \(err)")
        case .success(let value):
            guard let ints = value.collection else {
                XCTFail("Expression should have returned a collection, instead received: \(value).")
                break
            }
            XCTAssertEqual(ints.filter { $0 == 10 }.count, 1, "Result: \(ints) should only contain one '10' for expression: \(test1)")
        }

        guard let expr = buildAST(for: test2) else {
            return
        }

        switch evaluate(expr) {
        case .failure(let err):
            XCTFail("Expression should have succeeded, instead received: \(err)")
        case .success(let value):
            guard let ints = value.collection else {
                XCTFail("Expression should have returned a collection, instead received: \(value).")
                break
            }
            XCTAssertEqual(ints.filter { $0 != 10 }.count, 1, "Result: \(ints) should only contain one value not equal to '10' for expression: \(test2)")
        }
    }

    func testRepeatStatement() {
        let test1 = "repeat x := 2d6 until (min x) =/= (max x)"
        let test2 = "repeat x := 2d6 while (min x) =/= (max x)"

        guard let expr = buildAST(for: test1) else {
            return
        }

        switch evaluate(expr) {
        case .failure(let err):
            XCTFail("Expression should have succeeded, instead received: \(err)")
        case .success(let value):
            guard let ints = value.collection else {
                XCTFail("Expression should have returned a collection, instead received: \(value).")
                break
            }
            XCTAssertEqual(ints.count, 2, "Should have received a collection of size 2, received size \(ints.count)")
            XCTAssertNotEqual(ints[0], ints[1], "Result: \(ints) should contain two different integers")
        }

        guard let expr = buildAST(for: test2) else {
            return
        }

        switch evaluate(expr) {
        case .failure(let err):
            XCTFail("Expression should have succeeded, instead received: \(err)")
        case .success(let value):
            guard let ints = value.collection else {
                XCTFail("Expression should have returned a collection, instead received: \(value).")
                break
            }
            XCTAssertEqual(ints.count, 2, "Should have received a collection of size 2, received size \(ints.count)")
            XCTAssertEqual(ints[0], ints[1], "Result: \(ints) should contain two identical integers")
        }
    }
}
