import Foundation

/// Deterministic xorshift64* PRNG. Same seed always produces the same sequence,
/// which is required so workout plans are stable for a given (profile, date).
public struct SeededRandom {
    private var state: UInt64

    public init(seed: UInt64) {
        // xorshift64* requires a non-zero state.
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    public mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 0x2545F4914F6CDD1D
    }

    public mutating func int(in range: ClosedRange<Int>) -> Int {
        precondition(range.lowerBound <= range.upperBound, "invalid range")
        let width = UInt64(range.upperBound - range.lowerBound) + 1
        let raw = next()
        // Use the upper bits, which mix better in xorshift* generators.
        let upperBits = raw >> 32
        let offset = width == 0 ? 0 : Int(upperBits % width)
        return range.lowerBound + offset
    }

    public mutating func pick<T>(_ array: [T]) -> T? {
        guard !array.isEmpty else { return nil }
        let index = int(in: 0...(array.count - 1))
        return array[index]
    }
}

/// Internal stable hash (FNV-1a) over a canonical string. Used for deterministic
/// plan seeding — NEVER use `hashValue`/`Hasher`, which are randomized per process.
enum StableHash {
    static func fnv1a(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x100000001b3
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        return hash
    }
}
