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
public struct ParallelMonteCarloTreeSearch<G, P where G: Game, P: MonteCarloTreeSearchPolicy, P.Game == G, P.Score == G.Score> {

    typealias Base = MonteCarloTreeSearch<G, P>

    let base: Base
    let threads: Int

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

    public init(game: G, player: G.Player, policy: P, threads: Int) {
        let base = MonteCarloTreeSearch<G, P>(game: game, player: player, policy: policy)
        self.init(base: base, threads: threads)
    }

    init(base: Base, threads: Int) {
        assert(threads > 0)
        self.base = base
        self.threads = threads
    }

    @warn_unused_result()
    public func update(move: G.Move) -> ParallelMonteCarloTreeSearch {
        let base = self.base.update(move)
        let threads = self.threads
        return ParallelMonteCarloTreeSearch(base: base, threads: threads)
    }

    @warn_unused_result()
    public func refine(randomSource: RandomSource = Strategist.defaultRandomSource) -> ParallelMonteCarloTreeSearch {
        guard self.player == self.game.currentPlayer else {
            return self
        }
        guard self.threads > 1 else {
            let base = self.base.refine(randomSource)
            let threads = self.threads
            return ParallelMonteCarloTreeSearch(base: base, threads: threads)
        }

        let asyncQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
        let qos_attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0)
        let syncQueue = dispatch_queue_create("com.domain.app.sync", qos_attr)

        var bases: [Base] = []
        dispatch_apply(self.threads, asyncQueue) { i in
            let base = self.base.refine(randomSource)
            dispatch_sync(syncQueue) {
                bases.append(base)
            }
        }
        if self.threads % 2 != 0 {
            let lhs = bases.removeLast()
            let rhs = bases.removeLast()
            let merged = lhs.mergeWith(rhs)
            bases.append(merged)
        }
        var count = bases.count
        bases.withUnsafeMutableBufferPointer { buffer in
            while bases.count > 1 {
                dispatch_apply(count / 2, asyncQueue) { i in
                    buffer[i] = buffer[i].mergeWith(buffer[i + (count / 2)])
                }
            }
            count /= 2
        }
        let base = bases[0]
        let threads = self.threads
        return ParallelMonteCarloTreeSearch(base: base, threads: threads)
    }

    @warn_unused_result()
    public func mergeWith(other: ParallelMonteCarloTreeSearch) -> ParallelMonteCarloTreeSearch {
        assert(self.base.game == other.base.game)
        assert(self.base.player == other.base.player)
        let base = self.base.mergeWith(other.base)
        let threads = self.threads
        return ParallelMonteCarloTreeSearch(base: base, threads: threads)
    }
}

extension ParallelMonteCarloTreeSearch: CustomDebugStringConvertible {
    public var debugDescription: String {
        return self.base.debugDescription
    }
}

extension ParallelMonteCarloTreeSearch: Strategy {
    public typealias Game = G

    public func evaluatedMoves(game: Game) -> AnySequence<(G.Move, Evaluation<Game.Score>)> {
        assert(game == self.game)
        assert(game.currentPlayer == self.player)
        return self.base.evaluatedMoves(game)
    }
}
