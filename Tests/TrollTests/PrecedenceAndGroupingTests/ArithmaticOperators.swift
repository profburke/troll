import Troll
import XCTest

final class ArithmaticOperators: XCTestCase {
    func testAddAndSubtract() {
        check(TestCase("10 - 5 - 3", .collection([2])))
        check(TestCase("5 - 1 + 4", .collection([8])))
    }

    func testMultiplyAndDivide() {
        check(TestCase("4 * 8 / 2", .collection([16])))
        check(TestCase("4 / 2 * 5", .collection([10])))
    }

    func testMix() {
        check(TestCase("1 + 2 * 3", .collection([7])))
        check(TestCase("10 - 4 / 2", .collection([8])))
    }

    func testMod() {
        check(TestCase("12 mod 7 mod 3", .collection([2])))
        check(TestCase("12 mod 7 + 3", .collection([8])))
        check(TestCase("3 + 12 mod 7", .collection([8])))
    }

    func testUnaryMinus() {
        check(TestCase("- -12", .collection([12]))) // recall "--" is multiset subtraction
        check(TestCase("- 3 + 5", .collection([2])))
    }
}
