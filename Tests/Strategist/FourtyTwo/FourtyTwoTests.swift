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
    typealias TreeSearchPolicy = SimpleTreeSearchPolicy<Game>
    typealias Player = FourtyTwoPlayer

    func testMiniMaxTreeSearch() {
        typealias Strategy = MiniMaxTreeSearch<Game, TreeSearchPolicy>

        var game = Game(player: Player())
        let policy = TreeSearchPolicy(maxMoves: 10, maxDepth: 10)
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
