import Troll
import XCTest

extension TokenType {
    var representation: String {
        switch self {
        case .die:
            return (Bool.random()) ? "d" : "D"
        case .zeroDie:
            return (Bool.random()) ? "z" : "Z"
        case .union:
            return "U"
        case .plus:
            return "+"
        case .times:
            return "*"
        case .divide:
            return "/"
        case .lparen:
            return "("
        case .rparen:
            return ")"
        case .comma:
            return ","
        case .semicolon:
            return ";"
        case .lbrace:
            return "{"
        case .rbrace:
            return "}"
        case .tilde:
            return "~"
        case .bang:
            return "!"
        case .and:
            return "&"
        case .hash:
            return "#"
        case .question:
            return "?"
        case .sample:
            return "'"
        case .lbrack:
            return "["
        case .rbrack:
            return "]"
        case .minus:
            return "-"
        case .setMinus:
            return "--"
        case .assign:
            return ":="
        case .eq:
            return "="
        case .neq:
            return "=/="
        case .lt:
            return "<"
        case .gt:
            return ">"
        case .le:
            return "<="
        case .ge:
            return ">="
        case .dotDot:
            return ".."
        case .hconc:
            return "||"
        case .vconcl:
            return "|>"
        case .vconcr:
            return "<|"
        case .vconcc:
            return "<>"
        case .first:
            return "%1"
        case .second:
            return "%2"
        case .integer:
            return "\(Int.random(in: 1...Int.max))"
        case .real:
            return "\(Float.random(in: 0.001 ..< 1.0))"
        case .identifier:
            return "Fred" // TBD
        case .string:
            return "\"How now?\"" // TBD
        case .sum:
            return "sum"
        case .sgn:
            return "sgn"
        case .mod:
            return "mod"
        case .least:
            return "least"
        case .largest:
            return "largest"
        case .count:
            return "count"
        case .drop:
            return "drop"
        case .keep:
            return "keep"
        case .pick:
            return "pick"
        case .median:
            return "median"
        case .`in`:
            return "in"
        case .`repeat`:
            return "repeat"
        case .accumulate:
            return "accumulate"
        case .`while`:
            return "while"
        case .until:
            return "until"
        case .foreach:
            return "foreach"
        case .`do`:
            return "do"
        case .`if`:
            return "if"
        case .then:
            return "then"
        case .`else`:
            return "else"
        case .min:
            return "min"
        case .max:
            return "max"
        case .minimal:
            return "minimal"
        case .maximal:
            return "maximal"
        case .choose:
            return "choose"
        case .different:
            return "different"
        case .function:
            return "function"
        case .call:
            return "call"
        case .compositional:
            return "compositional"
        case .EOF:
            return "<<<<EOF>>>>" // TBD
        }
    }
}

final class ScannerTests: XCTestCase {

    private func scan(_ source: String) -> Result<[Token], Troll.Scanner.ScannerError> {
        Troll.Scanner(source).scan()
    }

    // MARK: - Error cases

    func testNoSource() {
        guard case .failure(let error) = scan("") else {
            XCTFail("Expected .noSource failure")
            return
        }
        XCTAssertEqual(error, .noSource)
    }

    func testUnexpectedCharacter() {
        guard case .failure(let error) = scan("$") else {
            XCTFail("Expected .unexpectedCharacter failure")
            return
        }
        XCTAssertEqual(error, .unexpectedCharacter)
    }

    func testUnterminatedString() {
        // A newline before the closing quote triggers unterminatedString.
        guard case .failure(let error) = scan("\"hello\n") else {
            XCTFail("Expected .unterminatedString failure")
            return
        }
        XCTAssertEqual(error, .unterminatedString)
    }

    func testMalformedColon() {
        // ':' must be followed by '=' to form ':='; anything else is malformed.
        guard case .failure(let error) = scan(":x") else {
            XCTFail("Expected .malformedToken failure")
            return
        }
        XCTAssertEqual(error, .malformedToken)
    }

    func testMalformedPipe() {
        // '|' must be followed by '|' or '>'; anything else is malformed.
        guard case .failure(let error) = scan("|x") else {
            XCTFail("Expected .malformedToken failure")
            return
        }
        XCTAssertEqual(error, .malformedToken)
    }

    func testMalformedPercent() {
        // '%' must be followed by '1' or '2'; anything else is malformed.
        guard case .failure(let error) = scan("%3") else {
            XCTFail("Expected .malformedToken failure")
            return
        }
        XCTAssertEqual(error, .malformedToken)
    }

    func testMalformedDot() {
        // '.' must be followed by '.' to form '..'; anything else is malformed.
        guard case .failure(let error) = scan(".x") else {
            XCTFail("Expected .malformedToken failure")
            return
        }
        XCTAssertEqual(error, .malformedToken)
    }

    // MARK: - Happy-path gaps

    func testStringLiteral() {
        guard case .success(let tokens) = scan("\"hello\"") else {
            XCTFail("Expected success scanning a string literal")
            return
        }
        XCTAssertEqual(tokens.count, 2)
        XCTAssertEqual(tokens[0].type, .string)
        XCTAssertEqual(tokens[1].type, .EOF)
    }

    func testComment() {
        // A backslash starts a line comment; everything up to the newline is ignored.
        guard case .success(let tokens) = scan("\\ comment\n5") else {
            XCTFail("Expected success scanning a comment")
            return
        }
        XCTAssertEqual(tokens.count, 2)
        XCTAssertEqual(tokens[0].type, .integer)
        XCTAssertEqual(tokens[1].type, .EOF)
    }

    // MARK: - Existing test

    func testScanFunction() {
        var tokenTypes: [TokenType] = []
        (0..<100).forEach { _ in
                            let type = TokenType.allCases.randomElement()!
                            if type != .EOF {
                                tokenTypes.append(type)
                            }
        }

        let text = tokenTypes.map { $0.representation }.joined(separator: " ") // TODO: do we _always_ want them space separated?
        tokenTypes.append(.EOF)
        
        let scanner = Scanner(text)
        let result = scanner.scan()

        switch result {
        case .failure(let error):
            XCTFail("Problem scanning: \(error)")
        case .success(let tokens):
            let types = tokens.map { $0.type }
            XCTAssertEqual(tokenTypes, types)
        }
    }
}
