//
//  RandomStrategy.swift
//  Strategist
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

/// Implementation of a simple random-based strategy.
///
/// - note: Due to the lack of internal state a single instance of `RandomStrategy` can be shared for several players in a game.
public struct RandomStrategy<G: Game>: Strategy {
    public typealias Game = G
    
    public init() {

    }
    
    public func evaluatedMoves(_ game: Game) -> AnySequence<(Game.Move, Evaluation<Game.Score>)> {
        let moves = game.availableMoves()
        return AnySequence(moves.lazy.map {
            return ($0, Evaluation.ongoing(Game.Score.mid))
        })
    }

    public func update(_ move: Game.Move) -> RandomStrategy {
        return self
    }
}
