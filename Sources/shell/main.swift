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

import func Darwin.exit
import func Darwin.fputs
import func Darwin.isatty
import var Darwin.stderr
import Foundation
import LineNoise
import Troll

class Troll {
    private let usage = "usage: troll [[N] <script> [ID1=N1] [ID2=N2] ... [IDn=Nn]]"

    private lazy var ln = LineNoise()
    private let interpreter = Interpreter()

    private let prompt = "troll> "
    private var hadError = false
    private var hadRuntimeError = false
    private var showTokens = false
    private var showTree = false

    public var isInteractive: Bool {
        return isatty(FileHandle.standardInput.fileDescriptor) == 1
    }

    private var historyfile: String {
        // Not sure if this works for Linux. Ought to use File URLs, but linenoise-swift
        // doesn't support them.
        return (NSHomeDirectory() as NSString).appendingPathComponent(".troll.history")
    }

    // Using the scanner is overkill, although it does allow us to
    // easily make sure identifiers have proper format, parse integers, etc.
    private func parse(args: [String]) {
        let scanner = Scanner(args.joined(separator: " "))

        guard case .success(let tokens) = scanner.scan() else {
            print(usage)
            exit(64)
        }

        let parser = Parser(tokens)
        let result = parser.parseArgs()

        switch result {
        case .failure:
            print(usage)
            exit(64)
        case .success(let symbols):
            interpreter.push(symbols)
        }
    }

    // Exit codes from sysexits.h; may be mis-interpreting some of them :)
    func run(args: [String]) {
        var filenameIndex = 1
        let repetitions: Int

        if let firstAsInt = Int(args[0]) {
            if firstAsInt < 1 {
                print(usage)
                exit(64)
            }
            repetitions = firstAsInt
        } else {
            filenameIndex = 0
            repetitions = 1
        }

        if filenameIndex == 1 && args.count < 2 {
            print(usage)
            exit(64)
        }
        
        let filename = args[filenameIndex]

        // TODO: is this correct?
        if args.count > filenameIndex + 1 {
            parse(args: Array(args[(filenameIndex + 1)...]))
        }

        do {
            let source = try String(contentsOfFile: filename, encoding: .utf8)
            run(source, repetitions: repetitions)

            if hadError {
                exit(64)
            }
            if hadRuntimeError {
                exit(70)
            }
        } catch {
            fputs("\(error.localizedDescription)\n", stderr)
            exit(66)
        }
    }

    func repl() {
        ln.setHistoryMaxLength(100)
        try? ln.loadHistory(fromFile: historyfile)
        defer {
            try? ln.saveHistory(toFile: historyfile)
        }

        while true {
            if let line = try? ln.getLine(prompt: prompt).trimmingCharacters(in: .whitespaces) {
                print()
                if line == "+scanner" {
                    showTokens = true
                } else if line == "-scanner" {
                    showTokens = false
                } else if line == "+parser" {
                    showTree = true
                } else if line == "-parser" {
                    showTree = false
                } else if line == "+quit" {
                    break
                } else if line == "+help" {
                    printHelp()
                } else if line == "+version" {
                    printVersion()
                } else if line == "+multiline" {
                    let script = doMultiline()
                    run(script)
                } else if line.starts(with: "+set") {
                    setVar(String(line.dropFirst(4)))
                } else if line.starts(with: "-set") {
                    unsetVar(String(line.dropFirst(4)))
                } else {
                    run(line)
                    ln.addHistory(line)
                }
            } else {
                break
            }
        }
    }

    func run(_ source: String, repetitions: Int = 1) {
        let scanner = Scanner(source)
        guard case let .success(tokens) = scanner.scan() else {
            hadError = true
            return
        }
        if showTokens { print(tokens) }

        let parser = Parser(tokens)
        guard case .success(let parsedData) = parser.parse() else {
            hadError = true
            return
        }
        if showTree { print("Tree: \(parsedData.expression)") }

        interpreter.add(parsedData.functions)

        (1...repetitions).forEach { _ in
            guard case let .success(value) = interpreter.evaluate(parsedData.expression) else {
                hadRuntimeError = true
                // TODO: should quit w/appropriate exit code
                return
            }
            
            print(value)
        }
    }

    private func unsetVar(_ line: String) {
        interpreter.remove(line.trimmingCharacters(in: .whitespaces))
    }

    private func setVar(_ line: String) {
        let scanner = Scanner(line)
        guard case .success(let tokens) = scanner.scan(),
              tokens.count == 3, /* 3rd token is EOF */
              tokens[0].type == .identifier,
              tokens[1].type == .integer else {
            print("usage: +set <identifier> <integer>")
            return
        }

        let identifier = tokens[0].lexeme
        guard case .integer(let i) = tokens[1].literal else {
            fatalError("Integer token w/out an integer as its literal value.")
        }

        interpreter.push(Symbol(identifier: identifier, value: .collection([i])))
    }

    private func printVersion() {
        print()
        print("Troll version \(interpreter.version)")
    }

    private func printHelp() {
        printVersion()
        print()
        print("""
            Commands:

            +help - print this message
            +multiline - enter a Troll script over multiple lines
            +/-parser - turn on/off printing of abstract syntax tree
            +/-scanner - turn on/off printing of token stream
            +set <identifier> <integer> - set a variable to be used in subsequent Troll expressions
            -set <identifier> - remove the definition for <identifier>
            +version - print the version

            +quit - quit the interpreter

            Any other line will be assumed to be a Troll script and parsed accordingly.

            """)
    }

    private func doMultiline() -> String {
        var script = ""

        print("Enter '+done' on its own line when you are finished.")
        while true {
            if let line = try? ln.getLine(prompt: "").trimmingCharacters(in: .whitespaces) {
                print()
                if line == "+done" {
                    break
                }
                script += " " + line
            }
        }

        return script
    }
}


//////////////////////////////////////////

let troll = Troll()
let argCount = CommandLine.arguments.count

if argCount == 1 {
    if troll.isInteractive {
        troll.repl()
    } else {
        guard let source
        = String(bytes: FileHandle.standardInput.availableData, encoding: .utf8) else {
            print("Error reading redirected input.")
            exit(64)
        }

        troll.run(source)
    }
} else {
    troll.run(args: Array(CommandLine.arguments[1...]))
}
