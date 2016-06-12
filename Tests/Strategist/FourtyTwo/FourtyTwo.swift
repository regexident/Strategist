//
//  FourtyTwo.swift
//  MiniMaxTests
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

import Strategist

struct FourtyTwoPlayer: Strategist.Player {}

func ==(lhs: FourtyTwoPlayer, rhs: FourtyTwoPlayer) -> Bool {
    return true
}

extension FourtyTwoPlayer: CustomStringConvertible {
    var description: String {
        return "Player"
    }
}

enum FourtyTwoMove: Strategist.Move {
    case Add(Int)
    case Mul(Int)
}

func ==(lhs: FourtyTwoMove, rhs: FourtyTwoMove) -> Bool {
    switch (lhs, rhs) {
    case let (.Add(lhsValue), .Add(rhsValue)):
        return lhsValue == rhsValue
    case let (.Mul(lhsValue), .Mul(rhsValue)):
        return lhsValue == rhsValue
    default:
        return false
    }
}

extension FourtyTwoMove: Hashable {
    var hashValue: Int {
        switch self {
        case let .Add(value): return value
        case let .Mul(value): return value
        }
    }
}

extension FourtyTwoMove: CustomStringConvertible {
    var description: String {
        switch self {
        case let .Add(value): return "+ \(value)"
        case let .Mul(value): return "* \(value)"
        }
    }
}

/// The objective of this ficticious single-player dummy game
/// is to reach exactly 42 with the least amount of moves by either
/// adding or multiplying the current total with either 2 or 3.
struct FourtyTwoGame: Strategist.Game {
    typealias Player = FourtyTwoPlayer
    typealias Move = FourtyTwoMove
    typealias Score = Double

    static let moves: [Move] = [
        .Add(2), .Add(3), .Mul(2), .Mul(3)
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

    private init(player: Player, sum: Int, moves: [Move]) {
        self.player = player
        self.sum = sum
        self.moves = moves
    }

    func update(move: Move) -> FourtyTwoGame {
        let player = self.player
        var sum = self.sum
        switch move {
        case let .Add(value): sum += value
        case let .Mul(value): sum *= value
        }
        var moves = self.moves
        moves.append(move)
        return FourtyTwoGame(player: player, sum: sum, moves: moves)
    }

    func playerAfter(player: Player) -> Player {
        return player
    }

    func playersAreAllied(players: (Player, Player)) -> Bool {
        return players.0 == players.1
    }

    func availableMoves() -> AnyGenerator<Move> {
        guard !self.isFinished else {
            return AnyGenerator { return nil }
        }
        return AnyGenerator(FourtyTwoGame.moves.generate())
    }

    func evaluate(forPlayer player: Player) -> Evaluation<Score> {
        guard self.sum < 42 else {
            let score = Double(-self.moves.count)
            return (self.sum == 42) ? .Victory(score) : .Defeat(score)
        }
        let score = Double(abs(42 - self.sum))
        return .Ongoing(score)
    }
}

func ==(lhs: FourtyTwoGame, rhs: FourtyTwoGame) -> Bool {
    guard lhs.player == rhs.player else {
        return false
    }
    guard lhs.sum == rhs.sum else {
        return false
    }
    guard lhs.moves == rhs.moves else {
        return false
    }
    return true
}

extension FourtyTwoGame: CustomStringConvertible {
    var description: String {
        return "\(self.sum) @ \(self.moves)"
    }
}
