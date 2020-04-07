//
//  MonteCarloTreeSearchStrategy.swift
//  Strategist
//
//  Created by Vincent Esche on 3/27/20.
//

public protocol MonteCarloTreeSearchStrategy: Strategy {
    mutating func refine(using randomSource: @escaping RandomSource)
    func refined(using randomSource: @escaping RandomSource) -> Self

    mutating func mergeWith(_ other: Self)
    func mergedWith(_ other: Self) -> Self
}

extension MonteCarloTreeSearchStrategy {
    public func refined(
        using randomSource: @escaping RandomSource = Int.random(in:)
    ) -> Self {
        var copy = self
        copy.refine(using: randomSource)
        return copy
    }

    public func mergedWith(_ other: Self) -> Self {
        var copy = self
        copy.mergeWith(other)
        return copy
    }
}
