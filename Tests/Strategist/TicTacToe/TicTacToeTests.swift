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
    typealias TreeSearchPolicy = SimpleTreeSearchPolicy<Game>
    typealias Player = TicTacToePlayer

    func testMiniMaxTreeSearch() {
        typealias Strategy = MiniMaxTreeSearch<Game, TreeSearchPolicy>

        let players: [Player] = [.X, .O]
        var game = Game(players: players)
        let policy = TreeSearchPolicy(maxMoves: 10, maxDepth: 10)
        let strategy = Strategy(policy: policy)
        while true {
            let evaluation = game.evaluate()
            guard !evaluation.isFinal else {
                // Correct deterministic AIs should always play draws against themselves:
                XCTAssertTrue(evaluation.isDraw)
                break
            }
            if let move = strategy.bestMove(game) {
                game = game.update(move)
            } else {
                XCTFail()
                break
            }
        }
    }
}
