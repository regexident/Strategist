//
//  FourtyTwo.swift
//  MiniMaxTests
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

import Strategist

struct FourtyTwoPlayer: Strategist.Player, Equatable, Hashable {}

extension FourtyTwoPlayer: CustomStringConvertible {
    var description: String {
        return "Player"
    }
}

enum FourtyTwoMove: Strategist.Move, Equatable, Hashable {
    case add(Int)
    case mul(Int)
}

extension FourtyTwoMove: CustomStringConvertible {
    var description: String {
        switch self {
        case let .add(value): return "+ \(value)"
        case let .mul(value): return "* \(value)"
        }
    }
}

/// The objective of this ficticious single-player dummy game
/// is to reach exactly 42 with the least amount of moves by either
/// adding or multiplying the current total with either 2 or 3.
struct FourtyTwoGame: Strategist.Game, Equatable, Hashable {
    typealias Player = FourtyTwoPlayer
    typealias Move = FourtyTwoMove
    typealias Score = Double

    static let moves: [Move] = [
        .add(2), .add(3), .mul(2), .mul(3)
    ]

    let player: FourtyTwoPlayer
    let sum: Int
    let moves: [Move]

    var currentPlayer: Player {
        return self.player
    }

    init(player: Player) {
        self.init(player: player, sum: 1, moves: [])
    }

    fileprivate init(player: Player, sum: Int, moves: [Move]) {
        self.player = player
        self.sum = sum
        self.moves = moves
    }

    func update(_ move: Move) -> FourtyTwoGame {
        let player = self.player
        var sum = self.sum
        switch move {
        case let .add(value): sum += value
        case let .mul(value): sum *= value
        }
        var moves = self.moves
        moves.append(move)
        return FourtyTwoGame(player: player, sum: sum, moves: moves)
    }

    func playerAfter(_ player: Player) -> Player {
        return player
    }

    func playersAreAllied(_ players: (Player, Player)) -> Bool {
        return players.0 == players.1
    }

    func availableMoves() -> AnyIterator<Move> {
        guard !self.isFinished else {
            return AnyIterator { return nil }
        }
        return AnyIterator(FourtyTwoGame.moves.makeIterator())
    }

    func evaluate(forPlayer player: Player) -> Evaluation<Score> {
        guard self.sum < 42 else {
            let score = Double(-self.moves.count)
            return (self.sum == 42) ? .victory(score) : .defeat(score)
        }
        let score = Double(abs(42 - self.sum))
        return .ongoing(score)
    }
}

extension FourtyTwoGame: CustomStringConvertible {
    var description: String {
        return "\(self.sum) @ \(self.moves)"
    }
}
