//
//  Strategy.swift
//  Strategist
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

/// Protocol to be implemented for strategy algorithms.
///
/// - requires: Must be immutable & have value semantics.
public protocol Strategy {
    /// The given game type to be reasoned about.
    associatedtype Game: Strategist.Game

    /// Evaluates the available moves for the `game`'s current state.
    /// 
    /// - returns: Lazy sequence of evaluated moves.
    func evaluatedMoves(game: Game) -> AnySequence<(Game.Move, Evaluation<Game.Score>)>

    /// Updates strategy's internal state for chosen `move`.
    /// 
    /// - returns: Updated strategy.
    func update(move: Game.Move) -> Self
}

extension Strategy {
    /// Evaluates the available moves for the `game`'s current state.
    ///
    /// - returns: Lazy sequence of evaluated moves.
    public func bestMoves(game: Game) -> [Game.Move] {
        var bestEvaluation = Evaluation<Game.Score>.min
        var bestMoves: [Game.Move] = []
        for (move, evaluation) in self.evaluatedMoves(game) {
            if evaluation == bestEvaluation {
                bestMoves.append(move)
            } else if evaluation > bestEvaluation {
                bestMoves.removeAll()
                bestMoves.append(move)
                bestEvaluation = evaluation
            }
        }
        return bestMoves
    }
}

/// Protocol for deterministic strategies
public protocol DeterministicStrategy: Strategy {}

extension DeterministicStrategy {
    /// Greedily selects the first encountered maximizing
    /// available move for the `game`'s current state.
    ///
    /// - note: The selection is deterministic.
    ///
    /// - returns: First maximizing available move.
    public func bestMove(game: Game) -> Game.Move? {
        let evaluatedMoves = self.evaluatedMoves(game)
        return evaluatedMoves.maxElement{ $0.1 < $1.1 }.map{ $0.0 }
    }
}

/// Protocol for non-deterministic strategies
public protocol NonDeterministicStrategy: Strategy {}

extension NonDeterministicStrategy {
    /// Randomly selects from the encountered maximizing
    /// available move for the `game`'s current state.
    ///
    /// - note: The selection is deterministic.
    ///
    /// - returns: Randomly chosen maximizing available move.
    public func bestMove(game: Game, randomSource: (UInt32 -> UInt32)? = nil) -> Game.Move? {
        var bestEvaluation = Evaluation<Game.Score>.min
        var bestMove: Game.Move? = nil
        var count = 0
        let evaluatedMoves = self.evaluatedMoves(game)
        guard let randomSource = randomSource else {
            return evaluatedMoves.maxElement{ $0.1 < $1.1 }.map { $0.0 }
        }
        for (move, evaluation) in evaluatedMoves {
            if evaluation > bestEvaluation {
                bestEvaluation = evaluation
                bestMove = move
                count = 1
            } else if evaluation == bestEvaluation {
                if Int(randomSource(UInt32(count))) == 0 {
                    bestMove = move
                }
                count += 1
            }
        }
        return bestMove
    }
}
