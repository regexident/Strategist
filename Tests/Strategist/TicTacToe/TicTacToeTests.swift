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

    func testMiniMaxTreeSearch() {
        typealias Policy = SimpleTreeSearchPolicy<Game>
        typealias Strategy = MiniMaxTreeSearch<Game, Policy>

        let players: [Player] = [.X, .O]
        var game = Game(players: players)
        let policy = Policy(maxMoves: 10, maxExplorationDepth: 10)
        let strategy = Strategy(policy: policy)
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

    func testNegaMaxTreeSearch() {
        typealias Policy = SimpleTreeSearchPolicy<Game>
        typealias Strategy = NegaMaxTreeSearch<Game, Policy>

        let players: [Player] = [.X, .O]
        var game = Game(players: players)
        let policy = Policy(maxMoves: 10, maxExplorationDepth: 10)
        let strategy = Strategy(policy: policy)
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

    func testMonteCarloTreeSearch() {
        typealias Policy = SimpleMonteCarloTreeSearchPolicy<Game>
        typealias Strategy = MonteCarloTreeSearch<Game, Policy>
        
        let rate = 0.75
        let plays = 10
        let wins = (0..<plays).reduce(0) { wins, _ in
            let players: [Player] = [.X, .O]
            var game = Game(players: players)
            let policy = Policy(
                maxMoves: 9,
                maxExplorationDepth: 9,
                maxSimulationDepth: 9,
                simulations: 100,
                pruningThreshold: 1000,
                c: sqrt(2.0)
            )
            var strategy = Strategy(game: game, player: players[0], policy: policy)
            let randomStrategy = RandomStrategy<TicTacToeGame>()
            var i = 0
            while true {
                let evaluation = game.evaluate()
                guard !evaluation.isFinal else {
                    if (i % 2 == 0) && (evaluation.isDraw || evaluation.isVictory) {
                        return wins + 1
                    } else if (evaluation.isDraw || evaluation.isDefeat) {
                        return wins + 1
                    }
                    return wins
                }
                if i % 2 == 0 {
                    let epochs = 10
                    for _ in 0..<epochs {
                        strategy = strategy.refine()
                    }
                }
                let move: TicTacToeMove
                if (i % 2 == 0) {
                    move = strategy.randomMaximizingMove(game)!
                } else {
                    move = randomStrategy.randomMaximizingMove(game)!
                }
                strategy = strategy.update(move)
                game = game.update(move)
                i += 1
            }
        }
        XCTAssert(wins >= Int(Double(plays) * rate))
    }
}
