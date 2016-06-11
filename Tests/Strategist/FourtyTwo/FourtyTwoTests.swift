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
}
