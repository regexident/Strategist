//
//  MiniMaxTests.swift
//  MiniMaxTests
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2015 Vincent Esche. All rights reserved.
//

import XCTest
@testable import Strategist

class FourtyTwoTests: XCTestCase {
    typealias Game = FourtyTwoGame
    typealias Player = FourtyTwoPlayer

    var cores: Int {
        ProcessInfo.processInfo.activeProcessorCount
    }

    func testMiniMaxTreeSearch() {
        typealias Policy = SimpleTreeSearchPolicy<Game>
        typealias Strategy = MiniMaxTreeSearch<Game, Policy>

        measure {
            var game = Game(player: Player())
            let policy = Policy(maxMoves: 10, maxExplorationDepth: 10)
            let strategy = Strategy(policy: policy)
            while true {
                let evaluation = game.evaluate()
                guard !evaluation.isFinal else {
                    XCTAssertTrue(evaluation.isVictory)
                    break
                }
                let move = strategy.randomMaximizingMove(game)!
                game = game.update(move)
            }
        }
    }

    func testNegaMaxTreeSearch() {
        typealias Policy = SimpleTreeSearchPolicy<Game>
        typealias Strategy = NegaMaxTreeSearch<Game, Policy>

        measure {
            var game = Game(player: Player())
            let policy = Policy(maxMoves: 10, maxExplorationDepth: 10)
            let strategy = Strategy(policy: policy)
            while true {
                let evaluation = game.evaluate()
                guard !evaluation.isFinal else {
                    XCTAssertTrue(evaluation.isVictory)
                    break
                }
                let move = strategy.randomMaximizingMove(game)!
                game = game.update(move)
            }
        }
    }

    func testMonteCarloTreeSearch() {
        typealias Heuristic = UpperConfidenceBoundHeuristic<Game>
        typealias Policy = SimpleMonteCarloTreeSearchPolicy<Game, Heuristic>
        typealias Strategy = MonteCarloTreeSearch<Game, Policy>

        let rate: Double = 0.75
        let plays: Int = 10
        var wins: Int = 0

        measure {
            wins = (0..<plays).reduce(0) { wins, _ in
                let player = Player()
                var game = Game(player: player)
                let heuristic = Heuristic(c: sqrt(2.0))
                let policy = Policy(
                    maxMoves: 10,
                    maxExplorationDepth: 10,
                    maxSimulationDepth: 20,
                    simulations: 100,
                    pruningThreshold: 1000,
                    scoringHeuristic: heuristic
                )
                var strategy = Strategy(game: game, player: player, policy: policy)
                while true {
                    let evaluation = game.evaluate()
                    guard !evaluation.isFinal else {
                        return wins + (evaluation.isVictory ? 1 : 0)
                    }
                    for _ in 0..<20 {
                        strategy = strategy.refine()
                    }
                    let move = strategy.randomMaximizingMove(game)!
                    game = game.update(move)
                    strategy = strategy.update(move)
                }
            }
        }

        XCTAssert(wins >= Int(Double(plays) * rate))
    }

    func testParallelMonteCarloTreeSearch() {
        typealias Heuristic = UpperConfidenceBoundHeuristic<Game>
        typealias Policy = SimpleMonteCarloTreeSearchPolicy<Game, Heuristic>
        typealias Strategy = ParallelMonteCarloTreeSearch<Game, Policy>

        let usedCores: Int = max(1, self.cores - 1)

        let parallelCount = 10
        let batchSize = min(1, (parallelCount + usedCores) / usedCores)

        let rate: Double = 0.75
        let plays: Int = 10
        var wins: Int = 0

        measure {
            wins = (0..<plays).reduce(0) { wins, _ in
                let player = Player()
                var game = Game(player: player)
                let heuristic = Heuristic(c: sqrt(2.0))
                let policy = Policy(
                    maxMoves: 10,
                    maxExplorationDepth: 10,
                    maxSimulationDepth: 20,
                    simulations: 100,
                    pruningThreshold: 1000,
                    scoringHeuristic: heuristic
                )
                var strategy = Strategy(
                    game: game,
                    player: player,
                    policy: policy,
                    parallelCount: parallelCount,
                    batchSize: batchSize
                )
                while true {
                    let evaluation = game.evaluate()
                    guard !evaluation.isFinal else {
                        return wins + (evaluation.isVictory ? 1 : 0)
                    }
                    for _ in 0..<20 {
                        strategy = strategy.refine()
                    }
                    let move = strategy.randomMaximizingMove(game)!
                    game = game.update(move)
                    strategy = strategy.update(move)
                }
            }
        }

        XCTAssert(wins >= Int(Double(plays) * rate))
    }
}
