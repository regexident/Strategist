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

    let base: Base
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

    public func update(_ move: G.Move) -> ParallelMonteCarloTreeSearch {
        return ParallelMonteCarloTreeSearch(
            base: self.base.update(move),
            parallelCount: self.parallelCount,
            batchSize: self.batchSize
        )
    }
    
    public func refine(_ randomSource: @escaping RandomSource = Strategist.defaultRandomSource) -> ParallelMonteCarloTreeSearch {
        guard self.player == self.game.currentPlayer else {
            return self
        }

        var count = self.parallelCount
        let batchSize = self.batchSize

        let batchCount = (count + batchSize - 1) / batchSize

        guard count > batchSize else {
            var refinedBase: Base = self.base
            for _ in 0..<batchSize {
                let lhs = refinedBase
                let rhs = refinedBase.refine(randomSource)
                refinedBase = lhs.mergeWith(rhs)
            }
            return ParallelMonteCarloTreeSearch(
                base: refinedBase,
                parallelCount: self.parallelCount,
                batchSize: self.batchSize
            )
        }

        var bases: [Base] = Array(unsafeUninitializedCapacity: count) { buffer, initializedCount in
            initializedCount = count

            let bufferStartIndex = buffer.baseAddress!
            let bufferEndIndex = bufferStartIndex + buffer.count

            DispatchQueue.concurrentPerform(iterations: batchCount) { batchIndex in
                let batchStartIndex = bufferStartIndex + (batchIndex * batchSize)
                let batchEndIndex = min(bufferEndIndex, batchStartIndex + batchSize)
                for pointer in batchStartIndex..<batchEndIndex {
                    let refinedBase = self.base.refine(randomSource)
                    pointer.initialize(to: refinedBase)
                }
            }
        }

        while count % 2 != 0 {
            let lhs = bases.removeLast()
            let rhs = bases.removeLast()
            let merged = lhs.mergeWith(rhs)
            bases.append(merged)
            count -= 1
        }

        assert(count % 2 == 0)

        bases.withUnsafeMutableBufferPointer { basesBufferPointer in
            while count > 1 {
                DispatchQueue.concurrentPerform(iterations: count / 2) { i in
                    let (lhs, rhs) = (i, i + (count / 2))
                    let lhsBase = basesBufferPointer[lhs]
                    let rhsBase = basesBufferPointer[rhs]
                    basesBufferPointer[lhs] = lhsBase.mergeWith(rhsBase)
                }
                count /= 2
            }
        }

        return ParallelMonteCarloTreeSearch(
            base: bases[0],
            parallelCount: self.parallelCount,
            batchSize: self.batchSize
        )
    }

    public func mergeWith(_ other: ParallelMonteCarloTreeSearch) -> ParallelMonteCarloTreeSearch {
        assert(self.base.game == other.base.game)
        assert(self.base.player == other.base.player)
        return ParallelMonteCarloTreeSearch(
            base: self.base.mergeWith(other.base),
            parallelCount: self.parallelCount,
            batchSize: self.batchSize
        )
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

extension ParallelMonteCarloTreeSearch: Strategy {
    public typealias Game = G

    public func evaluatedMoves(_ game: Game) -> AnySequence<(G.Move, Evaluation<Game.Score>)> {
        assert(game == self.game)
        assert(game.currentPlayer == self.player)
        return self.base.evaluatedMoves(game)
    }
}
