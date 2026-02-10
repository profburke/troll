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
            return "\(Int.random(in: Int.min...Int.max))"
        case .real:
            return "\(Float.random(in: -0.999 ..< 1.0))"
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
