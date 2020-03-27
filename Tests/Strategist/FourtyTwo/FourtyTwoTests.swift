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

        var game = Game(player: Player())
        let policy = Policy(maxMoves: 10, maxExplorationDepth: 10)
        let strategy = Strategy(policy: policy)

        measure {
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

        var game = Game(player: Player())
        let policy = Policy(maxMoves: 10, maxExplorationDepth: 10)
        let strategy = Strategy(policy: policy)

        measure {
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

        var generator = DeterministicRandomNumberGenerator(seed: (0, 1, 2, 3))
        let randomSource: (Range<Int>) -> Int = { range in
            Int.random(in: range, using: &generator)
        }

        measure {
            while true {
                let evaluation = game.evaluate()
                guard !evaluation.isFinal else {
                    XCTAssert(evaluation.isVictory, "Expected to win")
                    return
                }

                strategy.refine(using: randomSource)

                let move = strategy.randomMaximizingMove(game, using: randomSource)!
                game = game.update(move)
                strategy = strategy.update(move)
            }
        }
    }

    func testParallelMonteCarloTreeSearch() {
        typealias Heuristic = UpperConfidenceBoundHeuristic<Game>
        typealias Policy = SimpleMonteCarloTreeSearchPolicy<Game, Heuristic>
        typealias Strategy = ParallelMonteCarloTreeSearch<Game, Policy>

        let usedCores: Int = max(1, self.cores - 1)

        let parallelCount = usedCores * 16
        let batchSize = (parallelCount + usedCores - 1) / usedCores

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

        var generator = DeterministicRandomNumberGenerator(seed: (0, 1, 2, 3))
        let randomSource: (Range<Int>) -> Int = { range in
            Int.random(in: range, using: &generator)
        }
        
        measure {
            while true {
                let evaluation = game.evaluate()
                guard !evaluation.isFinal else {
                    XCTAssert(evaluation.isVictory, "Expected to win")
                    return
                }
                strategy = strategy.refine(using: randomSource)
                let move = strategy.randomMaximizingMove(game, using: randomSource)!
                game = game.update(move)
                strategy = strategy.update(move)
            }
        }
    }
}
