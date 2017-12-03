//
//  Strategist.swift
//  Strategist
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

import Darwin

/// Function type used for injecting random sources into Strategist.
public typealias RandomSource = (UInt32) -> UInt32

/// Convenience function for generating curried fake random sources.
public func fakeRandomSource(_ output: UInt32) -> RandomSource {
    return { upperBound in
        assert(output < upperBound)
        return output
    }
}

/// The default random source to use unless provided explicitly.
public func defaultRandomSource(_ upperBound: UInt32) -> UInt32 {
    return arc4random_uniform(upperBound)
}

/// A lightweight player descriptor.
///
/// #### Example:
///
/// ```
/// enum ChessPlayer: Strategist.Player {
///     case White
///     case Black
/// }
/// ```
public protocol Player: Equatable {}

/// A lightweight move descriptor.
///
/// #### Example:
///
/// ```
/// struct ChessMove: Strategist.Move {
///     let origin: (UInt8, UInt8)
///     let destination: (UInt8, UInt8)
/// }
/// ```
public protocol Move: Hashable {}

/// A representation of a game's state.
///
/// - requires: Must be immutable & have value semantics.
/// - note: Depending on the game's nature it may be appropriate to model
/// the game's state as a history of moves, in addition to a simple snapshot.
///
/// #### Snapshot Only:
///
/// ```
/// enum ChessPlayer: Strategist.Player {
///     case White
///     case Black
/// }
/// enum ChessPiece {
///     case King, Queen, Rook, Bishop, Knight, Pawn
/// }
/// struct ChessGame: Strategist.State {
///     let board: [ChessPiece?]
///     let player: ChessPlayer?
/// }
/// ```
///
/// #### Snapshot + History:
///
/// ```
/// enum GoPlayer: Strategist.Player {
///     case White
///     case Black
/// }
/// enum GoStone {
///     case White, Black
/// }
/// struct GoGame: Strategist.Game {
///     let board: [GoStone?]
///     let moves: [GoMove]
///     let player: GoPlayer?
/// }
/// ```
public protocol Game: Equatable {
    /// A representation of a game's moves.
    associatedtype Move: Strategist.Move
    /// A representation of a game's state.
    associatedtype Player: Strategist.Player
    /// A representation of a game's evaluation.
    associatedtype Score: Strategist.Score

    /// The player who the turn was handed over by last player's move
    /// or the game's initial player if no move has been made yet.
    var currentPlayer: Player { get }

    /// Advance the game by applying a move to the game's current state and advancing the players' turn.
    ///
    /// - returns: An updated game at the newly calculated state.
    func update(_ move: Move) -> Self

    /// Checks whether two players are expected to cooperate.
    func playersAreAllied(_ players: (Player, Player)) -> Bool

    /// All available moves for the next turn's player given the game's current state.
    ///
    /// - recommended: Generate the moves lazily to reduce the memory overhead.
    func availableMoves() -> AnyIterator<Move>

    /// Evaluate the game at its current state for the current player.
    ///
    /// - returns: Evaluation of game's current state from the perspective of the game's current player.
    func evaluate(forPlayer player: Player) -> Evaluation<Score>
}

extension Game {
    /// Evaluate the game at its current state for the current player.
    ///had
    /// - returns: Evaluation of game's current state from the perspective of the game's current player.
    public func evaluate() -> Evaluation<Score> {
        return self.evaluate(forPlayer: self.currentPlayer)
    }

    /// Checks whether the game has reached a final state.
    ///
    /// - returns: `false` iff `self.evaluate()` would return `.Ongoing(_)`, otherwise `true`.
    public var isFinished: Bool {
        switch self.evaluate() {
        case .ongoing(_): return false
        default: return true
        }
    }
}

/// A representation of a game with support for rewinding.
///
/// - requires: Must be immutable & have value semantics.
public protocol ReversibleGame: Game {
    /// Rewind the game by undoing a move to the game's current state.
    ///
    /// - returns: An updated game at the newly calculated prior state.
    func reverse(_ move: Move) -> Self
}
