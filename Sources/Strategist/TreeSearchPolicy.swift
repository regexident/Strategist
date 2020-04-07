//
//  TreeSearchPolicy.swift
//  Strategist
//
//  Created by Vincent Esche on 09/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

/// Policy for more direct control over a strategy's execution
public protocol TreeSearchPolicy {
    /// The given game type to be reasoned about.
    associatedtype Game: Strategist.Game

    /// Filter out moves to be ignored at any stage of the game.
    func filterMoves<G: IteratorProtocol>(_ state: Game, depth: Int, moves: G) -> AnyIterator<Game.Move> where G.Element == Game.Move

    /// Whether the strategy should abort a given exploration.
    func hasReachedMaxExplorationDepth(_ depth: Int) -> Bool
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

    public func filterMoves<G: IteratorProtocol>(_ state: Game, depth: Int, moves: G) -> AnyIterator<Game.Move> where G.Element == Game.Move {
        return AnyIterator(moves.take(self.maxMoves))
    }

    public func hasReachedMaxExplorationDepth(_ depth: Int) -> Bool {
        return depth >= self.maxExplorationDepth
    }
}
