//
//  MiniMaxTests.swift
//  MiniMaxTests
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2015 Vincent Esche. All rights reserved.
//

import XCTest
@testable import Strategist

class TicTacToeTests: XCTestCase {
    typealias Game = TicTacToeGame
    typealias Player = TicTacToePlayer

    var cores: Int {
        ProcessInfo.processInfo.activeProcessorCount
    }

    func testMiniMaxTreeSearch() {
        typealias Policy = SimpleTreeSearchPolicy<Game>
        typealias Strategy = MiniMaxTreeSearch<Game, Policy>

        let players: [Player] = [.x, .o]
        var game = Game(players: players)
        let policy = Policy(maxMoves: .max, maxExplorationDepth: 3)
        let strategy = Strategy(policy: policy)
        
        measure {
            while true {
                let evaluation = game.evaluate()
                guard !evaluation.isFinal else {
                    // Correct deterministic AIs should always play draws against themselves:
                    XCTAssertTrue(evaluation.isDraw)
                    break
                }
                if let move = strategy.randomMaximizingMove(game) {
                    game = game.update(move)
                } else {
                    XCTFail()
                    break
                }
            }
        }
    }

    func testNegaMaxTreeSearch() {
        typealias Policy = SimpleTreeSearchPolicy<Game>
        typealias Strategy = NegaMaxTreeSearch<Game, Policy>

        let players: [Player] = [.x, .o]
        var game = Game(players: players)
        let policy = Policy(maxMoves: 10, maxExplorationDepth: 10)
        let strategy = Strategy(policy: policy)

        measure {
            while true {
                let evaluation = game.evaluate()
                guard !evaluation.isFinal else {
                    // Correct deterministic AIs should always play draws against themselves:
                    XCTAssertTrue(evaluation.isDraw)
                    break
                }
                if let move = strategy.randomMaximizingMove(game) {
                    game = game.update(move)
                } else {
                    XCTFail()
                    break
                }
            }
        }
    }

    func testMonteCarloTreeSearch() {
        typealias Heuristic = UpperConfidenceBoundHeuristic<Game>
        typealias Policy = SimpleMonteCarloTreeSearchPolicy<Game, Heuristic>
        typealias Strategy = MonteCarloTreeSearch<Game, Policy>

        let players: [Player] = [.x, .o]
        var game = Game(players: players)
        let heuristic = Heuristic(c: sqrt(2.0))
        let policy = Policy(
            maxMoves: 9,
            maxExplorationDepth: 9,
            maxSimulationDepth: 9,
            simulations: 100,
            pruningThreshold: 1000,
            scoringHeuristic: heuristic
        )
        var strategy = Strategy(game: game, player: players[0], policy: policy)
        let randomStrategy = RandomStrategy<TicTacToeGame>()

        measure {
            for i in 0... {
                let evaluation = game.evaluate()
                guard !evaluation.isFinal else {
                    if (i % 2 == 0) && (evaluation.isDraw || evaluation.isVictory) {
                        XCTAssert(evaluation.isVictory || evaluation.isDraw, "Expected to win or draw")
                    } else if (evaluation.isDraw || evaluation.isDefeat) {
                        XCTAssert(evaluation.isVictory || evaluation.isDefeat, "Expected to win or lose")
                    }
                    return
                }
                if i % 2 == 0 {
                    strategy = strategy.refine()
                }
                let move: TicTacToeMove
                if (i % 2 == 0) {
                    move = strategy.randomMaximizingMove(game)!
                } else {
                    move = randomStrategy.randomMaximizingMove(game)!
                }
                strategy = strategy.update(move)
                game = game.update(move)
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

        let players: [Player] = [.x, .o]
        var game = Game(players: players)
        let heuristic = Heuristic(c: sqrt(2.0))
        let policy = Policy(
            maxMoves: 9,
            maxExplorationDepth: 9,
            maxSimulationDepth: 9,
            simulations: 100,
            pruningThreshold: 1000,
            scoringHeuristic: heuristic
        )
        var strategy = Strategy(
            game: game,
            player: players[0],
            policy: policy,
            parallelCount: parallelCount,
            batchSize: batchSize
        )
        let randomStrategy = RandomStrategy<TicTacToeGame>()

        measure {
            for i in 0... {
                let evaluation = game.evaluate()
                guard !evaluation.isFinal else {
                    if (i % 2 == 0) && (evaluation.isDraw || evaluation.isVictory) {
                        XCTAssert(evaluation.isVictory || evaluation.isDraw, "Expected to win or draw")
                    } else if (evaluation.isDraw || evaluation.isDefeat) {
                        XCTAssert(evaluation.isVictory || evaluation.isDefeat, "Expected to win or lose")
                    }
                    return
                }
                if i % 2 == 0 {
                    strategy = strategy.refine()
                }
                let move: TicTacToeMove
                if (i % 2 == 0) {
                    move = strategy.randomMaximizingMove(game)!
                } else {
                    move = randomStrategy.randomMaximizingMove(game)!
                }
                strategy = strategy.update(move)
                game = game.update(move)
            }
        }
    }
}
