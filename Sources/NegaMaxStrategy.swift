//
//  NegaMaxTreeSearch.swift
//  Strategist
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

/// Implementation of [Negamax Tree Search](https://en.wikipedia.org/wiki/Negamax#Negamax_with_alpha_beta_pruning) algorithm with [alpha beta pruning](https://en.wikipedia.org/wiki/Alpha%E2%80%93beta_pruning).
///
/// - note: Due to the lack of internal state a single instance of `NegaMaxTreeSearch` can be shared for several players in a game.
public struct NegaMaxTreeSearch<G, P: TreeSearchPolicy> where P.Game == G {
    let policy: P

    public init(policy: P) {
        self.policy = policy
    }

    func negamax(_ game: Game, rootPlayer: G.Player, payload: NegaMaxPayload<G.Score>) -> Evaluation<G.Score> {
        let evaluation = game.evaluate()
        guard !self.policy.hasReachedMaxExplorationDepth(payload.depth) && !evaluation.isFinal else {
            return evaluation
        }
        let nextDepth = payload.depth + 1
        let currentPlayerIsAlly = game.playersAreAllied((rootPlayer, game.currentPlayer))
        var bestMove = Evaluation<G.Score>.min
        var (alpha, beta) = (payload.alpha, payload.beta)
        let moves = game.availableMoves()
        let filteredMoves = self.policy.filterMoves(game, depth: payload.depth, moves: moves)
        for move in filteredMoves {
            let nextGame = game.update(move)
            let nextPlayerIsAlly = game.playersAreAllied((rootPlayer, nextGame.currentPlayer))
            let (nextAlpha, nextBeta): (Evaluation<G.Score>, Evaluation<G.Score>)
            if currentPlayerIsAlly == nextPlayerIsAlly {
                (nextAlpha, nextBeta) = (alpha, beta)
            } else {
                (nextAlpha, nextBeta) = (beta.inverse(), alpha.inverse())
            }
            let nextPayload = NegaMaxPayload(alpha: nextAlpha, beta: nextBeta, depth: nextDepth)
            let result = self.negamax(nextGame, rootPlayer: rootPlayer, payload: nextPayload)
            let evaluation: Evaluation<G.Score>
            if currentPlayerIsAlly == nextPlayerIsAlly {
                evaluation = result
            } else {
                evaluation = result.inverse()
            }
            alpha = max(alpha, evaluation)
            bestMove = alpha
            if alpha >= beta {
                break
            }
        }
        return bestMove
    }
}

extension NegaMaxTreeSearch: Strategy {

    public typealias Game = G
    
    public func evaluatedMoves(_ game: Game) -> AnySequence<(Game.Move, Evaluation<G.Score>)> {
        let player = game.currentPlayer
        let moves = game.availableMoves()
        let filteredMoves = self.policy.filterMoves(game, depth: 0, moves: moves)
        return AnySequence(filteredMoves.lazy.map { move in
            let nextGame = game.update(move)
            let nextPlayer = nextGame.currentPlayer
            let payload = NegaMaxPayload<G.Score>()
            let result = self.negamax(nextGame, rootPlayer: player, payload: payload)
            let players = (player, nextPlayer)
            let nextPlayerIsAlly = game.playersAreAllied(players)
            let evaluation = nextPlayerIsAlly ? result : result.inverse()
            return (move, evaluation)
        })
    }

    public mutating func update(_ move: Game.Move) {
        // does nothing
    }
}

struct NegaMaxPayload<S: Score> {
    let alpha: Evaluation<S>
    let beta: Evaluation<S>
    let depth: Int

    init() {
        self.init(alpha: Evaluation<S>.min, beta: Evaluation<S>.max, depth: 0)
    }

    init(alpha: Evaluation<S>, beta: Evaluation<S>, depth: Int) {
        self.alpha = alpha
        self.beta = beta
        self.depth = depth
    }
}
