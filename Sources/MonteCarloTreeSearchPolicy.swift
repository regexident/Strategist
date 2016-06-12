//
//  Policy.swift
//  Strategist
//
//  Created by Vincent Esche on 09/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

import Darwin

public protocol MonteCarloTreeSearchPolicy: TreeSearchPolicy {
    func hasReachedMaxSimulationDepth(depth: Int) -> Bool
    func shouldContinueSimulations(game: Game, simulationCount: Int) -> Bool
    func shouldCollapseTree(stats: TreeStats, subtrees: Int, depth: Int) -> Bool
    func explorationHeuristic(stats: TreeStats, n: Int) -> Game.Score
    func simulationHeuristic(game: Game, randomSource: RandomSource) -> Game.Move?
}

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
    
    public func filterMoves(state: Game, depth: Int, moves: AnyGenerator<Game.Move>) -> AnyGenerator<Game.Move> {
        return AnyGenerator(moves.generate().take(self.maxMoves))
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

    public func explorationHeuristic(stats: TreeStats, n: Int) -> Game.Score {
        let wi = Double(stats.score)
        let ni = Double(stats.plays)
        let n = Double(n)
        return (wi / ni) + self.c * sqrt(log(n) / ni)
    }
}