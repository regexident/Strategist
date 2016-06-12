//
//  Policy.swift
//  Strategist
//
//  Created by Vincent Esche on 09/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

import Darwin

/// Policy for more direct control over a strategy's execution
public protocol MonteCarloTreeSearchPolicy: TreeSearchPolicy {
    /// Whether the strategy should abort a given simulation.
    func hasReachedMaxSimulationDepth(depth: Int) -> Bool
    /// Whether the strategy should execute another simulation.
    func shouldContinueSimulations(game: Game, simulationCount: Int) -> Bool
    /// Whether the strategy should collapse a given tree into a single leaf node.
    func shouldCollapseTree(stats: TreeStats, subtrees: Int, depth: Int) -> Bool
    /// Heuristic used for choosing game state subtree to further explore.
    func explorationHeuristic(stats: TreeStats, n: Int) -> Game.Score
    /// Heuristic used for choosing game state subtree to further explore.
    func simulationHeuristic(game: Game, randomSource: RandomSource) -> Game.Move?
}

/// Simple minimal implementation of `MonteCarloTreeSearchPolicy`.
public struct SimpleMonteCarloTreeSearchPolicy<G: Game where G.Score == Double>: MonteCarloTreeSearchPolicy {
    public typealias Game = G

    public let maxMoves: Int
    public let maxExplorationDepth: Int
    public let maxSimulationDepth: Int
    public let simulations: Int
    public let pruningThreshold: Int
    public let c: Double

    public init(maxMoves: Int, maxExplorationDepth: Int, maxSimulationDepth: Int, simulations: Int, pruningThreshold: Int, c: Double = sqrt(2.0)) {
        self.maxMoves = maxMoves
        self.maxExplorationDepth = maxExplorationDepth
        self.maxSimulationDepth = maxSimulationDepth
        self.simulations = simulations
        self.pruningThreshold = pruningThreshold
        self.c = c
    }
    
    public func filterMoves<G: GeneratorType where G.Element == Game.Move>(state: Game, depth: Int, moves: G) -> AnyGenerator<Game.Move> {
        return AnyGenerator(moves.take(self.maxMoves))
    }

    public func hasReachedMaxExplorationDepth(depth: Int) -> Bool {
        return depth >= self.maxExplorationDepth
    }

    public func hasReachedMaxSimulationDepth(depth: Int) -> Bool {
        return depth >= self.maxSimulationDepth
    }

    public func shouldContinueSimulations(game: Game, simulationCount: Int) -> Bool {
        return simulationCount < self.simulations
    }

    public func shouldCollapseTree(stats: TreeStats, subtrees: Int, depth: Int) -> Bool {
        return (stats.score == 0) && (stats.plays > self.pruningThreshold)
    }

    public func simulationHeuristic(game: Game, randomSource: RandomSource) -> Game.Move? {
        var moves = game.availableMoves()
        return moves.sample(randomSource)
    }

    /// Upper Confidence Bound 1 applied to trees ([UCT](https://en.wikipedia.org/wiki/Monte_Carlo_tree_search#Exploration_and_exploitation))
    public func explorationHeuristic(stats: TreeStats, n: Int) -> Game.Score {
        let wi = Double(stats.score)
        let ni = Double(stats.plays)
        let n = Double(n)
        return (wi / ni) + self.c * sqrt(log(n) / ni)
    }
}