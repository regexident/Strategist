//
//  MonteCarloTreeSearch.swift
//  Strategist
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

import Foundation

/// Implementation of [Monte Carlo Tree Search](https://en.wikipedia.org/wiki/Monte_Carlo_tree_search) algorithm.
///
/// - note: Due to internal state a separate instance of `MonteCarloTreeSearch` has to be used for for each player in a game.
public struct ParallelMonteCarloTreeSearch<G, P> where P: MonteCarloTreeSearchPolicy, P.Game == G, P.Score == G.Score {

    typealias Base = MonteCarloTreeSearch<G, P>

    var base: Base
    let parallelCount: Int
    let batchSize: Int

    public var game: G {
        return self.base.game
    }

    public var player: G.Player {
        return self.base.player
    }

    public var policy: P {
        return self.base.policy
    }

    var tree: Base.Tree {
        return self.base.tree
    }

    public init(game: G, player: G.Player, policy: P, parallelCount: Int, batchSize: Int) {
        let base = MonteCarloTreeSearch<G, P>(game: game, player: player, policy: policy)
        self.init(base: base, parallelCount: parallelCount, batchSize: batchSize)
    }

    init(base: Base, parallelCount: Int, batchSize: Int) {
        assert(parallelCount > 0)
        assert(batchSize > 0)

        self.base = base
        self.parallelCount = parallelCount
        self.batchSize = batchSize
    }

    public mutating func update(_ move: G.Move) {
        self.base.update(move)
    }
}

extension ParallelMonteCarloTreeSearch: Strategy {
    public typealias Game = G

    public func evaluatedMoves(_ game: Game) -> AnySequence<(G.Move, Evaluation<Game.Score>)> {
        assert(game == self.game)
        assert(game.currentPlayer == self.player)

        return self.base.evaluatedMoves(game)
    }
}

extension ParallelMonteCarloTreeSearch: MonteCarloTreeSearchStrategy {
    public mutating func refine(
        using randomSource: @escaping RandomSource = Int.random(in:)
    ) {
        guard self.player == self.game.currentPlayer else {
            return
        }

        let count = self.parallelCount
        let batchSize = self.batchSize

        let batchCount = (count + batchSize - 1) / batchSize

        let bases: [Base] = Array(unsafeUninitializedCapacity: count) { buffer, initializedCount in
            initializedCount = count

            let base = self.base
            let bufferStartIndex = buffer.startIndex
            let bufferEndIndex = buffer.endIndex

            let refineBatch: (UnsafeMutableBufferPointer<Base>, Int) -> () = { buffer, batchIndex in
                let batchStartIndex = bufferStartIndex + (batchIndex * batchSize)
                let batchEndIndex = min(bufferEndIndex, batchStartIndex + batchSize)
                let batchRange = batchStartIndex..<batchEndIndex
                Self.refineBatch(base: base, bufferSlice: buffer[batchRange], randomSource: randomSource)
            }

            guard batchCount > 1 else {
                refineBatch(buffer, 0)
                return
            }

            DispatchQueue.concurrentPerform(iterations: batchCount) { batchIndex in
                refineBatch(buffer, batchIndex)
            }

            Self.mergeBases(bufferSlice: buffer[...], count: batchCount, stride: batchSize)
        }

        self.base = bases[0]
    }

    public mutating func mergeWith(_ other: ParallelMonteCarloTreeSearch) {
        assert(self.base.game == other.base.game)
        assert(self.base.player == other.base.player)

        self.base.mergeWith(other.base)
    }
}

extension ParallelMonteCarloTreeSearch {
    private static func refineBatch(
        base: Base,
        bufferSlice: Slice<UnsafeMutableBufferPointer<Base>>,
        randomSource: @escaping RandomSource
    ) {
        let batchSize = bufferSlice.count
        let batchStartIndex = bufferSlice.startIndex
        let batchEndIndex = bufferSlice.endIndex

        guard let bufferBaseAddress = bufferSlice.base.baseAddress else {
            fatalError("Expected `baseAddress`, found nil")
        }
        for index in batchStartIndex..<batchEndIndex {
            let pointer = bufferBaseAddress + index
            let refinedBase = base.refined(using: randomSource)
            pointer.initialize(to: refinedBase)
        }

        guard batchSize > 1 else {
            return
        }

        Self.mergeBases(bufferSlice: bufferSlice, count: batchSize, stride: 1)
    }

    private static func mergeBases(bufferSlice: Slice<UnsafeMutableBufferPointer<Base>>, count: Int, stride: Int) {
        var bufferSlice = bufferSlice
        let bufferSliceStartIndex = bufferSlice.startIndex
        let bufferSliceIndices = bufferSlice.indices

        var count = count

        guard count > 1 else {
            return
        }

        if count % 2 != 0 {
            let (lhs, rhs) = (
                bufferSliceStartIndex + ((count - 2) * stride),
                bufferSliceStartIndex + ((count - 1) * stride)
            )
            assert(bufferSliceIndices.contains(lhs))
            assert(bufferSliceIndices.contains(rhs))
            let lhsBase = bufferSlice[lhs]
            let rhsBase = bufferSlice[rhs]
            bufferSlice[lhs] = lhsBase.mergedWith(rhsBase)
            count -= 1
        }

        assert(count % 2 == 0, "The count should by now be evenly dividable by 2")

        while count > 1 {
            let halfCount = count / 2
            for index in 0..<halfCount {
                let (lhs, rhs) = (
                    bufferSliceStartIndex + (index * stride),
                    bufferSliceStartIndex + ((index + halfCount) * stride)
                )
                assert(bufferSliceIndices.contains(lhs))
                assert(bufferSliceIndices.contains(rhs))
                let lhsBase = bufferSlice[lhs]
                let rhsBase = bufferSlice[rhs]
                bufferSlice[lhs] = lhsBase.mergedWith(rhsBase)
            }
            count = halfCount
        }
    }
}

extension ParallelMonteCarloTreeSearch: CustomDebugStringConvertible
where
    G.Move: CustomDebugStringConvertible
{
    public var debugDescription: String {
        return self.base.debugDescription
    }
}
