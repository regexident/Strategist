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

    func testMiniMaxTreeSearch() {
        typealias Policy = SimpleTreeSearchPolicy<Game>
        typealias Strategy = MiniMaxTreeSearch<Game, Policy>

        var game = Game(player: Player())
        let policy = Policy(maxMoves: 10, maxExplorationDepth: 10)
        let strategy = Strategy(policy: policy)
        while true {
            let evaluation = game.evaluate()
            guard !evaluation.isFinal else {
                XCTAssertTrue(evaluation.isVictory)
                break
            }
            let move = strategy.bestMove(game)!
            game = game.update(move)
        }
    }

    func testNegaMaxTreeSearch() {
        typealias Policy = SimpleTreeSearchPolicy<Game>
        typealias Strategy = NegaMaxTreeSearch<Game, Policy>

        var game = Game(player: Player())
        let policy = Policy(maxMoves: 10, maxExplorationDepth: 10)
        let strategy = Strategy(policy: policy)
        while true {
            let evaluation = game.evaluate()
            guard !evaluation.isFinal else {
                XCTAssertTrue(evaluation.isVictory)
                break
            }
            let move = strategy.bestMove(game)!
            game = game.update(move)
        }
    }

    func testMonteCarloTreeSearch() {
        typealias Policy = SimpleMonteCarloTreeSearchPolicy<Game>
        typealias Strategy = MonteCarloTreeSearch<Game, Policy>

        let randomSource = arc4random_uniform
        let rate = 0.75
        let plays = 10
        let wins = (0..<plays).reduce(0) { wins, _ in
            let player = Player()
            var game = Game(player: player)
            let policy = Policy(
                maxMoves: 10,
                maxExplorationDepth: 10,
                maxSimulationDepth: 20,
                simulations: 100,
                pruningThreshold: 1000,
                c: sqrt(2.0)
            )
            var strategy = Strategy(game: game, player: player, policy: policy)
            while true {
                let evaluation = game.evaluate()
                guard !evaluation.isFinal else {
                    return wins + (evaluation.isVictory ? 1 : 0)
                }
                for _ in 0..<20 {
                    strategy = strategy.refine(randomSource)
                }
                let move = strategy.bestMove(game, randomSource: randomSource)!
                game = game.update(move)
                strategy = strategy.update(move)
            }
        }
        XCTAssert(wins >= Int(Double(plays) * rate))
    }
}