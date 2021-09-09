// https://gist.github.com/khanlou/77545f6e0af328c913397d7ac79be34e

func zip<S1, S2, T, U>(_ sequence1: S1, default d1: T, _ sequence2: S2, default d2: U) -> Zip2DefaultSequence<S1, S2, T, U> {
    return Zip2DefaultSequence<S1, S2, T, U>(sequence1: sequence1, default1: d1, sequence2: sequence2, default2: d2)
}

func zip<S1, S2, T>(_ sequence1: S1, _ sequence2: S2, default: T) -> Zip2DefaultSequence<S1, S2, T, T> {
    return Zip2DefaultSequence<S1, S2, T, T>(sequence1: sequence1, default1: `default`, sequence2: sequence2, default2: `default`)
}

struct Zip2DefaultSequence<S1: Sequence, S2: Sequence, T, U>: Sequence where S1.Element == T, S2.Element == U {
    let sequence1: S1
    let sequence2: S2
    let default1: T
    let default2: U

    init(sequence1: S1, default1: T, sequence2: S2, default2: U) {
        self.sequence1 = sequence1
        self.sequence2 = sequence2
        self.default1 = default1
        self.default2 = default2
    }

    func makeIterator() -> AnyIterator<(T,U)> {
        var i1 = sequence1.makeIterator()
        var i2 = sequence2.makeIterator()
        return AnyIterator({
            let next1 = i1.next()
            let next2 = i2.next()
            if next1 == nil && next2 == nil {
                return nil
            }
            return (next1 ?? self.default1, next2 ?? self.default2)
        })
    }
}
