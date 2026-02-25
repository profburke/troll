# Test Suite Findings

Analysis of the existing unit tests in `Tests/TrollTests/`.

---

## Executive Summary

The test suite has solid coverage in the binary and unary operator areas but has meaningful gaps in scanner error paths, parser error paths, and several source files that are entirely untested. One critical correctness issue was found: a non-functional test with no assertions.

---

## Critical Issues

### 1. `ExtractionTests.swift` is a non-functional placeholder

`testExtraction()` calls `"this <> or |> that".extractConcatenationOperators()` and *prints* the result — no assertions whatsoever. The test always passes regardless of behavior. The `String+Box.swift` string-manipulation helpers are effectively untested.

### 2. The `pick` operator lacks a without-replacement verification

`CollectionSingletonTests.swift` contains a `// TODO: need to verify that the selection takes place w/out replacement` comment. The assertion is absent — the without-replacement guarantee is not verified.

### 3. No direct parser tests exist

`Parser.swift` is tested only indirectly through every other test. All five `ParserError` cases are completely untested:
- `invalidRedefinition`
- `malformedArgument`
- `missingCondition`
- `needsVariable`
- `unexpectedToken`

### 4. `ScannerTests.swift` only tests the happy path

One test (`testScanFunction`) generates 100 random valid tokens and checks their types. None of the four `ScannerError` cases are tested:
- `malformedToken`
- `noSource`
- `unexpectedCharacter`
- `unterminatedString`

---

## Missing Coverage by Source File

| Source File | Current Coverage | Gap |
|---|---|---|
| `Parser.swift` | Indirect only | No error-path or edge-case tests |
| `Scanner.swift` | Minimal (1 test) | All error cases untested; string literals, comments untested |
| `String+Box.swift` | None (stub test) | All string helper methods untested |
| `ErrorReporter.swift` | None | Both reporter implementations untested |
| `Token.swift` | None | Token equality and description untested |
| `Interpreter.swift` | Indirect | Symbol push/pop/lookup, `reset()` untested directly |
| `Foreach.swift` | 1 test case | Empty input, single-element, nested cases missing |
| `Tuple.swift` | 2 cases | Only `%1`/`%2` on a 2-tuple; construction, nesting, out-of-bounds missing |
| `UtilitiyMethods.swift` | None | `parenthesize` and `zip` helpers untested |
| `Zip2DefaultSequence.swift` | None | Custom sequence untested |

---

## Test Quality Issues

- **Weak probabilistic-test iterations**: `testNondeterministicOperators` in `SingletonTests` runs only 100 iterations; uniform-distribution bias would go undetected.
- **`FunctionTests::testCallFunction`** only asserts `collection.count == 5`; element ranges and distribution are not checked.
- **`ValueTests`** only tests 6 cases; edge cases such as single-element collections, large collections, and negative numbers are absent.
- **`ProbabilisticChoiceTests`** only tests `?0.0` as the invalid boundary; `?1.0` (which should also be invalid under open-interval semantics) is not tested.
- **`StatementTests::testForeachStatement`** tests a single input; empty collection, single-element collection, and complex body expressions are not covered.
- **No division or modulo by zero tests** appear anywhere in `BinaryOperatorTests/`.
- **No tests for `RuntimeError.invalidBinaryOperator` or `RuntimeError.invalidUnaryOperator`**.

---

## Positive Observations

- `UnaryOperatorTests/` and `BinaryOperatorTests/` are the strongest areas — good error-path and deterministic-value coverage across value type combinations.
- `CollectionCollectionTests.swift` tests `{2, 2, 3} -- {2, 4}` twice with expected values `[2, 3]` and `[3, 2]`: these are equal under `Value.==` (which sorts before comparing), so the two cases are semantically identical and together serve as an implicit regression test for order-independent collection equality.
- `TestHelpers.swift` provides a clean, reusable evaluation harness (`evaluate`, `expectError`, etc.) that makes adding new tests straightforward.
- `StatementTests` covers `if`, `repeat` (both `while` and `until` forms), and `accumulate` reasonably well.

---

## Prioritized Recommendations

1. **Fix or replace `ExtractionTests.swift`** — add real assertions or delete it; a passing test with no assertions is actively misleading.
2. **Add `ScannerError` tests** — cover `unexpectedCharacter`, `unterminatedString`, `malformedToken`, and `noSource`.
3. **Add `ParserError` tests** — one test per error case is sufficient to establish coverage and prevent regressions.
4. **Complete the `pick` without-replacement assertion** in `CollectionSingletonTests.swift`.
5. **Add division/modulo by zero tests** to `BinaryOperatorTests/`.
6. **Add `Foreach` edge cases** — empty collection, single-element collection.
7. **Add `Tuple` construction and out-of-bounds tests**.
8. **Add `RuntimeError.invalidBinaryOperator` / `invalidUnaryOperator` tests**.
9. **Increase probabilistic-test iteration counts** or use a fixed seed for determinism in nondeterministic-operator tests.
