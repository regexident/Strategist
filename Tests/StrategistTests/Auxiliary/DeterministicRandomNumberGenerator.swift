/// Implementation of the xoroshiro256** PRNG:
///
/// Paper: http://vigna.di.unimi.it/ftp/papers/ScrambledLinear.pdf
struct DeterministicRandomNumberGenerator {
    typealias State = (UInt64, UInt64, UInt64, UInt64)

    private(set) var state: State

    init(seed: State) {
        precondition(seed != (0, 0, 0, 0))
        state = seed
    }

    init() {
        var generator = SystemRandomNumberGenerator()
        repeat {
            state = (generator.next(), generator.next(), generator.next(), generator.next())
        } while state == (0, 0, 0, 0)
    }

    private static func rotl(_ x: UInt64, _ k: UInt64) -> UInt64 {
        return (x << k) | (x >> (64 &- k))
    }
}

extension DeterministicRandomNumberGenerator: RandomNumberGenerator {
    mutating func next() -> UInt64 {
        var state = self.state

        let result = Self.rotl(state.1 &* 5, 7) &* 9

        let t = state.1 << 17
        state.2 ^= state.0
        state.3 ^= state.1
        state.1 ^= state.2
        state.0 ^= state.3

        state.2 ^= t

        state.3 = Self.rotl(state.3, 45)

        self.state = state

        return result
    }
}
