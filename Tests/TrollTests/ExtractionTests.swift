//
//  ExtractionTests.swift
//  TrollTests
//
//  Created by Matthew Burke on 9/7/21.
//

import Troll
import XCTest

final class ExtractionTests: XCTestCase {
    func testExtraction() {
        let s = "this <> or |> that".extractConcatenationOperators()
        print(s)
    }
}
