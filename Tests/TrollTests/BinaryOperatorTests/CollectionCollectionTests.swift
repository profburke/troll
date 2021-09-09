//
//  CollectionCollectionTests.swift
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

final class CollectionCollectionTests: XCTestCase {
    func testShouldFailIfLeftOperandNotACollection() {
        guard let expr = buildAST(for: "\"hello\" drop {1, 2}") else {
            return
        }

        guard case .failure(let reason) = evaluate(expr) else {
            XCTFail("Expected `evaluate` to fail.")
            return
        }
        XCTAssertEqual(reason, .needsIntCollection)
    }

    func testShouldFailIfRightOperandNotACollection() {
        guard let expr = buildAST(for: "{1, 2, 3} drop \"hello\"") else {
            return
        }

        guard case .failure(let reason) = evaluate(expr) else {
            XCTFail("Expected `evaluate` to fail.")
            return
        }
        XCTAssertEqual(reason, .needsIntCollection)
    }

    func testDeterministicOperators() {
        [
            TestCase("{1, 2} & {5, 7}", .collection([5, 7])),
            TestCase("{} & {5, 7}", .collection([])),
            TestCase("{2, 2, 3} drop {2, 4}", .collection([3])),
            TestCase("{2, 2, 3, 4} keep {2, 5}", .collection([2, 2])),
            TestCase("{2, 2, 3} -- {2, 4}", .collection([2, 3])),
            TestCase("{2, 2, 3} -- {2, 4}", .collection([3, 2])),
            TestCase("{1, 2, 3} U {2, 3, 4}", .collection([1, 2, 2, 3, 3, 4])),
            TestCase("{5, 7} @ {4, 6}", .collection([4, 5, 6, 7])),
        ]
        .forEach { testCase in
            check(testCase)
        }
    }
}
