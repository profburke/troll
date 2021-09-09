//
//  Value.swift
//  Troll
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

public enum Value {
    case collection([Int])
    case double(Double)
    indirect case pair(Value, Value)
    case string(String)

    // Not sure that these computed variables actually simplify the code...

    public var collection: [Int]? {
        if case let .collection(ints) = self {
            return ints
        } else {
            return nil
        }
    }

    public var double: Double? {
        if case let .double(value) = self {
            return value
        } else {
            return nil
        }
    }
    
    public var integer: Int? {
        if case let .collection(values) = self, values.count == 1 {
            return values[0]
        } else {
            return nil
        }
    }

    public var isTruthy: Bool {
        if case let .collection(ints) = self {
            return ints.count > 0
        } else {
            return false
        }
    }

    public var isFalsey: Bool {
        return !isTruthy
    }

    public var string: String? {
        if case let .string(value) = self {
            return value
        } else {
            return nil
        }
    }
}

extension Value: Equatable {
    public static func ==(lhs: Value, rhs: Value) -> Bool {
        switch (lhs, rhs) {
        case (.collection(let left), .collection(let right)):
            return left.sorted() == right.sorted()
        case (.double(let left), .double(let right)):
            // should we check using an epsilon?
            return left == right
        case (.pair(let leftFirst, let leftSecond), .pair(let rightFirst, let rightSecond)):
            return leftFirst == rightFirst && leftSecond == rightSecond
        case (.string(let left), .string(let right)):
            return left == right
        default:
            return false
        }
    }
}

extension Value: CustomStringConvertible {
    public var description: String {
        switch self {
        case .collection(let ints):
            return (ints.count == 1) ? "\(ints[0])"
                : ints.sorted().map { "\($0)" }.joined(separator: " ")
        case .double(let d):
            return "?\(d)"
        case .pair(let first, let second):
            return "[ \(first), \(second) ]"
        case .string(let text):
            return text
        }
    }
}
