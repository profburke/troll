//
//  ExtractionTests.swift
//  TrollTests
//
//  Created by Matthew Burke on 9/7/21.
//

import Troll
import XCTest

final class ExtractionTests: XCTestCase {

    // MARK: - extractConcatenationOperators

    func testNoOperators() {
        XCTAssertEqual("hello".extractConcatenationOperators(), ["hello"])
    }

    func testEmptyString() {
        XCTAssertEqual("".extractConcatenationOperators(), [""])
    }

    func testVconcCenter() {
        XCTAssertEqual("a <> b".extractConcatenationOperators(), ["a ", "<>", " b"])
    }

    func testVconcLeft() {
        XCTAssertEqual("a |> b".extractConcatenationOperators(), ["a ", "|>", " b"])
    }

    func testVconcRight() {
        XCTAssertEqual("a <| b".extractConcatenationOperators(), ["a ", "<|", " b"])
    }

    func testHconc() {
        XCTAssertEqual("a || b".extractConcatenationOperators(), ["a ", "||", " b"])
    }

    func testMultipleOperators() {
        XCTAssertEqual(
            "this <> or |> that".extractConcatenationOperators(),
            ["this ", "<>", " or ", "|>", " that"]
        )
    }

    func testAllFourOperators() {
        XCTAssertEqual(
            "a <> b |> c <| d || e".extractConcatenationOperators(),
            ["a ", "<>", " b ", "|>", " c ", "<|", " d ", "||", " e"]
        )
    }

    func testOperatorAtStart() {
        XCTAssertEqual("<> rest".extractConcatenationOperators(), ["", "<>", " rest"])
    }

    func testOperatorAtEnd() {
        XCTAssertEqual("start <>".extractConcatenationOperators(), ["start ", "<>", ""])
    }

    func testOperatorOnly() {
        XCTAssertEqual("<>".extractConcatenationOperators(), ["", "<>", ""])
    }

    func testAdjacentOperators() {
        XCTAssertEqual("<>|>".extractConcatenationOperators(), ["", "<>", "", "|>", ""])
    }

    // MARK: - split(usingRegex:)

    func testSplitInvalidRegexReturnsNil() {
        XCTAssertNil("hello".split(usingRegex: "[invalid"))
    }

    func testSplitNoMatch() {
        XCTAssertEqual("hello".split(usingRegex: "x"), ["hello"])
    }

    func testSplitIncludesSeparators() {
        XCTAssertEqual("a,b,c".split(usingRegex: ","), ["a", ",", "b", ",", "c"])
    }

    // MARK: - String+Box

    func testLines() {
        XCTAssertEqual("a\nb\nc".lines, ["a", "b", "c"])
    }

    func testLinesSingleLine() {
        XCTAssertEqual("hello".lines, ["hello"])
    }

    func testHeight() {
        XCTAssertEqual("a\nb\nc".height, 3)
    }

    func testHeightSingleLine() {
        XCTAssertEqual("hello".height, 1)
    }

    func testWidth() {
        XCTAssertEqual("ab\ncde\nf".width, 3)
    }

    func testWidthSingleLine() {
        XCTAssertEqual("hello".width, 5)
    }

    func testWidthEmpty() {
        XCTAssertEqual("".width, 0)
    }
}
