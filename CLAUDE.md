# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
swift build                          # Build all targets
swift run troll                      # Run the interactive REPL
swift run troll <file.troll>         # Execute a Troll script file
swift test                           # Run all tests
swift test --filter TrollTests       # Run tests in a specific test target
swift test --filter ScannerTests     # Run a specific test class
swift test --filter "ScannerTests/testFoo"  # Run a single test method
```

Debug flags in the REPL:
- `+scanner` — print token output from the scanner
- `+parser` — print AST output from the parser

## Architecture

This is a classic interpreter pipeline for the Troll dice-roll language:

**Scanner** (`Sources/Troll/Scanner.swift`) → tokenizes source into `Token` values
**Parser** (`Sources/Troll/Parser.swift`) → recursive-descent parser producing an AST
**Interpreter** (`Sources/Troll/Interpreter.swift`) → walks the AST and evaluates expressions

### Core Types

- **`Value`** (`Sources/Troll/Value.swift`) — the runtime value enum: `.collection([Int])`, `.double(Double)`, `.tuple([Value])`, `.string(String)`
- **`Expr`** (`Sources/Troll/Expr.swift`) — protocol with a single requirement: `evaluate(interpreter: Interpreter) throws -> Value`. Every AST node type conforms to this.
- **`Token`** (`Sources/Troll/Token.swift`) — ~50 token types covering all Troll operators, keywords, and literals

### Package Targets

| Target | Type | Purpose |
|--------|------|---------|
| `Troll` | Library | Core interpreter (Scanner, Parser, Interpreter, AST nodes) |
| `shell` | Executable | REPL and script runner; uses LineNoise for readline support |
| `TrollTests` | Test | Tests for the `Troll` library |

### Test Organization

Tests live in `Tests/TrollTests/` and are organized into subdirectories:
- `BinaryOperatorTests/` — operator behavior across value type combinations
- `UnaryOperatorTests/` — unary ops on singletons, collections, tuples
- `PrecedenceAndGroupingTests/` — operator precedence rules
- Top-level: `ScannerTests`, `ValueTests`, `VariableTests`, `FunctionTests`, `StatementTests`, `ExtractionTests`, `ProbabilisticChoiceTests`
- `TestHelpers.swift` — shared test utilities (helpers for evaluating expressions)
