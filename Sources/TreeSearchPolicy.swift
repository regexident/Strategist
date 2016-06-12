//
//  TreeSearchPolicy.swift
//  Strategist
//
//  Created by Vincent Esche on 09/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

import Darwin

/// Policy for more direct control over a strategy's execution
public protocol TreeSearchPolicy {
    /// The given game type to be reasoned about.
    associatedtype Game: Strategist.Game

    /// Filter out moves to be ignored at any stage of the game.
    func filterMoves(state: Game, depth: Int, moves: AnyGenerator<Game.Move>) -> AnyGenerator<Game.Move>

    /// Whether the strategy should abort a given exploration.
    func hasReachedMaxExplorationDepth(depth: Int) -> Bool
}

/// Simple minimal implementation of `TreeSearchPolicy`.
public struct SimpleTreeSearchPolicy<G: Game>: TreeSearchPolicy {
    public typealias Game = G

    public let maxMoves: Int
    public let maxExplorationDepth: Int

    public init(maxMoves: Int, maxExplorationDepth: Int) {
        self.maxMoves = maxMoves
        self.maxExplorationDepth = maxExplorationDepth
    }

    public func filterMoves(state: Game, depth: Int, moves: AnyGenerator<Game.Move>) -> AnyGenerator<Game.Move> {
        return AnyGenerator(moves.generate().take(self.maxMoves))
    }

    public func hasReachedMaxExplorationDepth(depth: Int) -> Bool {
        return depth >= self.maxExplorationDepth
    }
}
