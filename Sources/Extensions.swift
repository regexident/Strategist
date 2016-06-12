//
//  Extensions.swift
//  Strategist
//
//  Created by Vincent Esche on 08/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

extension GeneratorType {
    /// Take first `0..<upperBound` elements of `self`.
    func take(upperBound: Int) -> Take<Self> {
        return Take(base: self, upperBound: upperBound)
    }
}

/// Take first `0..<upperBound` elements of `self`.
struct Take<G: GeneratorType>: GeneratorType {
    typealias Base = G
    typealias Element = Base.Element

    var base: Base
    var upperBound: Int

    init(base: Base, upperBound: Int) {
        self.base = base
        self.upperBound = upperBound
    }

    mutating func next() -> Element? {
        guard self.upperBound > 0 else {
            return nil
        }
        self.upperBound -= 1
        return self.base.next()
    }
}

extension CollectionType where Index == Int {
    /// Select random element from `self`.
    ///
    /// - complexity: O(1).
    /// - returns: Randomly selected element from `self`.
    func sample(randomSource: RandomSource = Strategist.defaultRandomSource) -> Generator.Element? {
        let count = self.count
        guard count > 0 else {
            return nil
        }
        let index = randomSource(UInt32(count))
        return self[Int(index)]
    }
}

extension GeneratorType {
    /// Select random element from `self`.
    ///
    /// - complexity: O(`Array(self).count`).
    /// - returns: Randomly selected element from `self`.
    mutating func sample(randomSource: RandomSource = Strategist.defaultRandomSource) -> Element? {
        var result = self.next()
        var count = 2
        while let element = self.next() {
            if randomSource(UInt32(count)) == 0 {
                result = element
            }
            count += 1
        }
        return result
    }
}
