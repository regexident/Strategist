//
//  MiniMaxTreeSearch.swift
//  Strategist
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

public struct MiniMaxTreeSearch<G: Game, P: TreeSearchPolicy where P.Game == G> {
    let policy: P

    public init(policy: P) {
        self.policy = policy
    }

    func minimax(game: Game, rootPlayer: G.Player, payload: MiniMaxPayload<G.Score>) -> Evaluation<G.Score> {
        let evaluation = game.evaluate(forPlayer: rootPlayer)
        guard !self.policy.hasReachedMaxExplorationDepth(payload.depth) && !evaluation.isFinal else {
            return evaluation
        }
        let maximize = game.playersAreAllied((rootPlayer, game.currentPlayer))
        var bestEvaluation = (maximize) ? Evaluation<G.Score>.min : Evaluation<G.Score>.max
        var (alpha, beta) = (payload.alpha, payload.beta)
        let nextDepth = payload.depth + 1
        let moves = game.availableMoves()
        let filteredMoves = self.policy.filterMoves(game, depth: payload.depth, moves: moves)
        for move in filteredMoves {
            let nextState = game.update(move)
            let nextPayload = MiniMaxPayload(alpha: alpha, beta: beta, depth: nextDepth)
            let evaluation = self.minimax(nextState, rootPlayer: rootPlayer, payload: nextPayload)
            if maximize {
                alpha = max(alpha, evaluation)
                bestEvaluation = max(bestEvaluation, alpha)
            } else {
                beta = min(beta, evaluation)
                bestEvaluation = min(bestEvaluation, beta)
            }
            if alpha >= beta {
                break
            }
        }
        return bestEvaluation
    }
}

extension MiniMaxTreeSearch: Strategy {
    public typealias Game = G

    public func evaluatedMoves(game: Game) -> AnySequence<(Game.Move, Evaluation<G.Score>)> {
        let rootPlayer = game.currentPlayer
        let moves = game.availableMoves()
        let filteredMoves = self.policy.filterMoves(game, depth: 0, moves: moves)
        return AnySequence(filteredMoves.lazy.map { move in
            let nextState = game.update(move)
            let payload = MiniMaxPayload<G.Score>()
            let evaluation = self.minimax(nextState, rootPlayer: rootPlayer, payload: payload)
            return (move, evaluation)
        })
    }

    public func update(move: Game.Move) -> MiniMaxTreeSearch {
        return self
    }
}

struct MiniMaxPayload<S: Score> {
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