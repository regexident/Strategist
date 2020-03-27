//
//  Policy.swift
//  Strategist
//
//  Created by Vincent Esche on 09/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

import Darwin

/// Heuristic used for scoring moves based on the statistics
/// obtained from previous Monte Carlo simulations.
public protocol ScoringHeuristic {
    /// The score type
    associatedtype Score: Comparable

    /// Scores a given move based on statistics obtained
    /// from previous Monte Carlo simulations.
    func scoreMove(_ stats: TreeStats, parentPlays: Int) -> Score
}

/// Upper Confidence Bound 1 applied to trees ([UCT](https://en.wikipedia.org/wiki/Monte_Carlo_tree_search#Exploration_and_exploitation))
public struct UpperConfidenceBoundHeuristic<G: Game>: ScoringHeuristic where G.Score == Double {
    public typealias Score = Double

    public let c: Double

    public init(c: Double = sqrt(2.0)) {
        self.c = c
    }

    public func scoreMove(_ moveStats: TreeStats, parentPlays: Int) -> Score {
        let wi = Double(moveStats.wins)
        let ni = Double(moveStats.plays)
        let n = Double(parentPlays)
        return (wi / ni) + self.c * sqrt(log(n) / ni)
    }
}

/// Policy for more direct control over a strategy's execution
public protocol MonteCarloTreeSearchPolicy: TreeSearchPolicy, ScoringHeuristic {
    /// Whether the strategy should abort a given simulation.
    func hasReachedMaxSimulationDepth(_ depth: Int) -> Bool

    /// Whether the strategy should execute another simulation.
    func shouldContinueSimulations(_ game: Game, simulationCount: Int) -> Bool
    /// Whether the strategy should collapse a given tree into a single leaf node.
    func shouldCollapseTree(_ stats: TreeStats, subtrees: Int, depth: Int) -> Bool

    /// Heuristic used for scoring a given move.
    func scoreMove(_ stats: TreeStats, parentPlays: Int) -> Score

    /// Calculate reward from an evaluation.
    ///
    /// #### Example:
    /// ```
    /// func reward(evaluation: Evaluation<Game.Score>) -> Int {
    ///     switch evaluation {
    ///     case .Victory: return 1
    ///     case .Defeat: return 0
    ///     default: return 0
    ///     }
    /// }
    /// ```
    func reward(_ evaluation: Evaluation<Game.Score>) -> Int

    /// Heuristic used for choosing game state subtree to further explore.
    func explorationMove<M: IteratorProtocol>(_ availableMoves: M, explorationDepth: Int, plays: Int, using randomSource: RandomSource) -> Game.Move? where M.Element == (Game.Move, TreeStats)
    /// Heuristic used for choosing game state subtree to further explore.
    func simulationMove<M: IteratorProtocol>(_ availableMoves: M, simulationDepth: Int, using randomSource: RandomSource) -> Game.Move? where M.Element == Game.Move
}

/// Simple minimal implementation of `MonteCarloTreeSearchPolicy`.
public struct SimpleMonteCarloTreeSearchPolicy<G, H>: MonteCarloTreeSearchPolicy where G: Game, G.Score == H.Score, H: ScoringHeuristic {
    public typealias Game = G
    public typealias Score = H.Score

    public let maxMoves: Int
    public let maxExplorationDepth: Int
    public let maxSimulationDepth: Int
    public let simulations: Int
    public let pruningThreshold: Int
    public let scoringHeuristic: H

    public init(maxMoves: Int, maxExplorationDepth: Int, maxSimulationDepth: Int, simulations: Int, pruningThreshold: Int, scoringHeuristic: H) {
        self.maxMoves = maxMoves
        self.maxExplorationDepth = maxExplorationDepth
        self.maxSimulationDepth = maxSimulationDepth
        self.simulations = simulations
        self.pruningThreshold = pruningThreshold
        self.scoringHeuristic = scoringHeuristic
    }
    
    public func filterMoves<M: IteratorProtocol>(_ state: Game, depth: Int, moves: M) -> AnyIterator<Game.Move> where M.Element == Game.Move {
        return AnyIterator(moves.take(self.maxMoves))
    }

    public func hasReachedMaxExplorationDepth(_ depth: Int) -> Bool {
        return depth >= self.maxExplorationDepth
    }

    public func hasReachedMaxSimulationDepth(_ depth: Int) -> Bool {
        return depth >= self.maxSimulationDepth
    }

    public func shouldContinueSimulations(_ game: Game, simulationCount: Int) -> Bool {
        return simulationCount < self.simulations
    }

    public func shouldCollapseTree(_ stats: TreeStats, subtrees: Int, depth: Int) -> Bool {
        return (stats.wins == 0) && (stats.plays > self.pruningThreshold)
    }

    public func scoreMove(_ moveStats: TreeStats, parentPlays: Int) -> Score {
        return self.scoringHeuristic.scoreMove(moveStats, parentPlays: parentPlays)
    }

    public func reward(_ evaluation: Evaluation<Game.Score>) -> Int {
        switch evaluation {
        case .victory: return 1
        case .defeat: return 0
        default: return 0
        }
    }

    public func explorationMove<M: IteratorProtocol>(_ availableMoves: M, explorationDepth: Int, plays: Int, using randomSource: RandomSource) -> Game.Move? where M.Element == (Game.Move, TreeStats) {
        var availableMoves = availableMoves
        let maxElement = availableMoves.sampleMaxElement(using: randomSource) { lhs, rhs in
            let lhsScore = self.scoringHeuristic.scoreMove(lhs.1, parentPlays: plays)
            let rhsScore = self.scoringHeuristic.scoreMove(rhs.1, parentPlays: plays)
            return lhsScore < rhsScore
        }
        return maxElement.map { $0.0 }
    }

    public func simulationMove<M: IteratorProtocol>(_ availableMoves: M, simulationDepth: Int, using randomSource: RandomSource) -> Game.Move? where M.Element == Game.Move {
        var availableMoves = availableMoves
        return availableMoves.sample(using: randomSource)
    }
}
