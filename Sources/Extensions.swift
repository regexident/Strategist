//
//  Extensions.swift
//  Strategist
//
//  Created by Vincent Esche on 08/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

extension IteratorProtocol {
    /// Take first `0..<upperBound` elements of `self`.
    func take(_ upperBound: Int) -> Take<Self> {
        return Take(base: self, upperBound: upperBound)
    }
}

/// Take first `0..<upperBound` elements of `self`.
struct Take<G: IteratorProtocol>: IteratorProtocol {
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

extension Collection where Index == Int, IndexDistance == Int {
    /// Select random element from `self`.
    ///
    /// - complexity: O(1).
    /// - returns: Randomly selected element from `self`.
    func sample(_ randomSource: RandomSource = Strategist.defaultRandomSource) -> Iterator.Element? {
        let count = self.count
        guard count > 0 else {
            return nil
        }
        let index = randomSource(UInt32(count))
        return self[Int(index)]
    }
}

extension IteratorProtocol {
    /// Select random element from `self`.
    ///
    /// - complexity: O(`Array(self).count`).
    /// - returns: Randomly selected element from `self`.
    mutating func sample(_ randomSource: RandomSource = Strategist.defaultRandomSource) -> Element? {
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

extension IteratorProtocol where Element : Comparable {
    //Returns a random sample from maximum elements in self or nil if the sequence is empty.
    //
    /// -complexity: O(elements.count).
    mutating func sampleMaxElement(randomSource: RandomSource = Strategist.defaultRandomSource) -> Element? {
        return self.sampleMaxElement(randomSource: randomSource) { $0 < $1 }
    }
}

extension IteratorProtocol {
    /// Returns a random sample from maximum elements in self or nil if the sequence is empty.
    ///
    /// - complexity: O(elements.count).
    /// - requires: `isOrderedBefore` is a strict weak ordering over `self`.
    mutating func sampleMaxElement(randomSource: RandomSource = Strategist.defaultRandomSource, isOrderedBefore: (Element, Element) throws -> Bool) rethrows -> Element? {
        guard var maxElement = self.next() else {
            return nil
        }
        var maxElementCount = 0
        while let element = self.next() {
            if try isOrderedBefore(maxElement, element) {
                maxElement = element
                maxElementCount = 1
            } else if try !isOrderedBefore(element, maxElement) {
                if randomSource(UInt32(maxElementCount)) == 0 {
                    maxElement = element
                }
                maxElementCount += 1
            }
        }
        return maxElement
    }
}
