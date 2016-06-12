//
//  Strategy.swift
//  Strategist
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

public protocol Strategy {
    associatedtype Game: Strategist.Game

    func evaluatedMoves(game: Game) -> AnySequence<(Game.Move, Evaluation<Game.Score>)>
}

extension Strategy {
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

public protocol DeterministicStrategy: Strategy {}

extension DeterministicStrategy {
    public func bestMove(game: Game) -> Game.Move? {
        let evaluatedMoves = self.evaluatedMoves(game)
        return evaluatedMoves.maxElement{ $0.1 < $1.1 }.map{ $0.0 }
    }
}

public protocol NonDeterministicStrategy: Strategy {}

extension NonDeterministicStrategy {
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
