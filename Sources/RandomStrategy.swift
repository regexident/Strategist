//
//  RandomStrategy.swift
//  Strategist
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

public struct RandomStrategy<G: Game>: Strategy {
    public typealias Game = G

    let maxBreadth: Int

    public init(maxBreadth: Int = Int.max) {
        self.maxBreadth = maxBreadth
    }

    public func evaluatedMoves(game: Game) -> AnySequence<(Game.Move, Evaluation<Game.Score>)> {
        let moves = game.availableMoves()
        return AnySequence(moves.lazy.map {
            return ($0, Evaluation.Ongoing(Game.Score.mid))
        })
    }
}

extension RandomStrategy: NonDeterministicStrategy {}
