//
//  CollectionSingletonTests.swift
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

final class CollectionSingletonTests: XCTestCase {
    func testShouldFailIfLeftOperandNotACollection() {
        guard let expr = buildAST(for: "\"hello\" pick 3") else {
            return
        }

        guard case .failure(let reason) = evaluate(expr) else {
            XCTFail("Expected `evaluate` to fail.")
            return
        }
        XCTAssertEqual(reason, .needsIntCollection)
    }

    func testShouldFailIfRightOperandNotASingleton() {
        guard let expr = buildAST(for: "{1, 2, 3, 4} pick {2, 3}") else {
            return
        }

        guard case .failure(let reason) = evaluate(expr) else {
            XCTFail("Expected `evaluate` to fail.")
            return
        }
        XCTAssertEqual(reason, .needsSingleton)
    }

    // TODO: need to verify that the selection takes place w/out replacement.
    func testNondeterministicOperators() {
        [
            (expr: "{1, 2, 3, 4} pick 2", expectedLength: 2),
            (expr: "{2, 2, 3, 4, 5} pick 2", expectedLength: 2),
            (expr: "{2, 3, 4} pick 4", expectedLength: 3),
            (expr: "{2, 3, 4} pick 3", expectedLength: 3),
        ]
        .forEach { testCase in
            guard let expr = buildAST(for: testCase.expr) else {
                return
            }

            switch evaluate(expr) {
            case .failure(let err):
                XCTFail("Expected 'evaluate' to succeed, instead failed with error: \(err).")
            case .success(let value):
                guard case .collection(let ints) = value else {
                    XCTFail("Value returned from 'pick' is not a collection.")
                    return
                }
                XCTAssertEqual(ints.count, testCase.expectedLength)
            }
        }
    }
}
