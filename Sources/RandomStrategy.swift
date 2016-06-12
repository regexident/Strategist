//
//  RandomStrategy.swift
//  Strategist
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

/// Implementation of a simple random-based strategy.
public struct RandomStrategy<G: Game>: Strategy {
    public typealias Game = G

    public init() {

    }
    
    public func evaluatedMoves(game: Game) -> AnySequence<(Game.Move, Evaluation<Game.Score>)> {
        let moves = game.availableMoves()
        return AnySequence(moves.lazy.map {
            return ($0, Evaluation.Ongoing(Game.Score.mid))
        })
    }

    public func update(move: Game.Move) -> RandomStrategy {
        return self
    }
}

extension RandomStrategy: NonDeterministicStrategy {}
