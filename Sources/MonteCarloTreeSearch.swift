//
//  MonteCarloTreeSearch.swift
//  Strategist
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

import Darwin
import Foundation

public struct MonteCarloTreeSearch<G, P where G: Game, P: MonteCarloTreeSearchPolicy, P.Game == G> {

    typealias Tree = Strategist.GameTree<TreeNode, G.Move>

    public let game: G
    public let player: G.Player
    public let policy: P

    let tree: Tree

    public init(game: G, player: G.Player, policy: P) {
        let tree = MonteCarloTreeSearch.initialTreeForGame(game)
        self.init(game: game, player: player, policy: policy, tree: tree)
    }

    init(game: G, player: G.Player, policy: P, tree: Tree) {
        self.game = game
        self.player = player
        self.policy = policy
        self.tree = tree
    }

    @warn_unused_result()
    public func update(move: G.Move) -> MonteCarloTreeSearch {
        let game = self.game.update(move)
        let player = self.player
        let policy = self.policy
        let tree = self.tree.analysis(leaf: { node in
            return MonteCarloTreeSearch.initialTreeForGame(self.game)
        }, branch: { node, edges in
            if let index = edges.indexOf({ $0.0 == move }) {
                return edges[index].1
            } else {
                return MonteCarloTreeSearch.initialTreeForGame(self.game)
            }
        })
        return MonteCarloTreeSearch(game: game, player: player, policy: policy, tree: tree)
    }

    @warn_unused_result()
    public func refine(randomSource: RandomSource = Strategist.defaultRandomSource) -> MonteCarloTreeSearch {
        guard self.player == self.game.currentPlayer else {
            return self
        }
        let game = self.game
        let player = self.player
        let policy = self.policy
        let payload = MonteCarloPayload<G>(game: self.game, randomSource: randomSource)
        let tree = self.refineSubtree(self.tree, payload: payload)
        return MonteCarloTreeSearch(game: game, player: player, policy: policy, tree: tree)
    }

    @warn_unused_result()
    public func mergeWith(other: MonteCarloTreeSearch) -> MonteCarloTreeSearch {
        assert(self.game == other.game)
        assert(self.player == other.player)
        let game = self.game
        let player = self.player
        let policy = self.policy
        let tree = MonteCarloTreeSearch.mergeTrees(lhs: self.tree, rhs: other.tree)
        return MonteCarloTreeSearch(game: game, player: player, policy: policy, tree: tree)
    }

    @warn_unused_result()
    func refineSubtree(subtree: Tree, payload: MonteCarloPayload<G>) -> Tree {
        let refinedSubtree: Tree = subtree.analysis(leaf: { node in
            if node.explorable {
                return self.refineExplorableSubtree(node, edges: [:], payload: payload)
            } else {
                return subtree
            }
        }, branch: { node, edges in
            if node.explorable {
                return self.refineExplorableSubtree(node, edges: edges, payload: payload)
            } else {
                return self.refineExploredSubtree(node, edges: edges, payload: payload)
            }
        })
        guard case .Branch(var node, let edges) = refinedSubtree where !node.explorable else {
            return refinedSubtree
        }
        guard self.policy.shouldCollapseTree(node.stats, subtrees: edges.count, depth: payload.explorationDepth) else {
            return refinedSubtree
        }
        node.explorable = true
        return .Leaf(node)
    }

    @warn_unused_result()
    func refineExplorableSubtree(node: TreeNode, edges: [G.Move: Tree], payload: MonteCarloPayload<G>) -> Tree {
        let exploredMoves = Set(edges.map { $0.0 })
        let moves = payload.game.availableMoves()
        let filteredMoves = policy.filterMoves(payload.game, depth: payload.explorationDepth, moves: moves)
        let unexploredMoves = filteredMoves.filter { !exploredMoves.contains($0) }
        var refinedSubtrees = edges
        var refinedNode = node
        if unexploredMoves.count > 0 {
            let index = Int(payload.randomSource(UInt32(unexploredMoves.count)))
            let move = unexploredMoves[index]
            let nextPayload = MonteCarloPayload<G>(
                game: payload.game.update(move),
                randomSource: payload.randomSource,
                explorationDepth: payload.explorationDepth + 1
            )
            let refinedSubtree = self.simulateSubtree(payload.game.currentPlayer, payload: nextPayload)
            let refinedSubnode = refinedSubtree.analysis(leaf: { node in node }, branch: { node, _ in node })
            refinedNode.stats += refinedSubnode.stats
            if !policy.hasReachedMaxExplorationDepth(payload.explorationDepth) {
                refinedSubtrees[move] = refinedSubtree
            }
        }
        refinedNode.explorable = unexploredMoves.count > 1
        return .Branch(refinedNode, refinedSubtrees)
    }

    @warn_unused_result()
    func refineExploredSubtree(node: TreeNode, edges: [G.Move: Tree], payload: MonteCarloPayload<G>) -> Tree {
        let n = node.stats.plays
        var branchesGenerator = edges.generate()
        var maxSubtree = branchesGenerator.next()!
        var maxScore = G.Score.min
        var count = 0
        while let (move, subtree) = branchesGenerator.next() {
            let subnode = subtree.analysis(leaf: { node in node }, branch: { node, _ in node })
            let score = self.policy.explorationHeuristic(subnode.stats, n: n)
            if score > maxScore {
                maxScore = score
                maxSubtree = (move, subtree)
                count = 1
            } else if score == maxScore {
                if Int(payload.randomSource(UInt32(count))) == 0 {
                    maxScore = score
                    maxSubtree = (move, subtree)
                }
                count += 1
            }
        }
        let (move, subtree) = maxSubtree
        let subnode = subtree.analysis(leaf: { node in node }, branch: { node, _ in node })
        var refinedNode = node
        refinedNode.stats -= subnode.stats
        let payload = MonteCarloPayload<G>(
            game: payload.game.update(move),
            randomSource: payload.randomSource,
            explorationDepth: payload.explorationDepth + 1
        )
        let refinedSubtree = self.refineSubtree(subtree, payload: payload)
        let refinedSubnode = refinedSubtree.analysis(leaf: { node in node }, branch: { node, _ in node })
        refinedNode.stats += refinedSubnode.stats
        var refinedSubtrees = edges
        refinedSubtrees[move] = refinedSubtree
        return .Branch(refinedNode, refinedSubtrees)
    }

    @warn_unused_result()
    func simulateSubtree(rootPlayer: G.Player, payload: MonteCarloPayload<G>) -> Tree {
        var evaluation = payload.game.evaluate(forPlayer: rootPlayer)
        guard !evaluation.isFinal else {
            let score = MonteCarloTreeSearch.evaluationAsDelta(evaluation)
            let stats = TreeStats(score: score, plays: 1)
            let node = TreeNode(stats: stats, explorable: false)
            return .Leaf(node)
        }
        var game = payload.game
        var score = 0
        var plays = 0
        while self.policy.shouldContinueSimulations(game, simulationCount: plays) {
            var simulationDepth = 0
            while !self.policy.hasReachedMaxSimulationDepth(simulationDepth) {
                evaluation = game.evaluate(forPlayer: rootPlayer)
                guard !evaluation.isFinal else {
                    break
                }
                let choice = self.policy.simulationHeuristic(game, randomSource: payload.randomSource)
                guard let move = choice else {
                    break
                }
                game = game.update(move)
                simulationDepth += 1
            }
            score += MonteCarloTreeSearch.evaluationAsDelta(evaluation)
            plays += 1
        }
        let stats = TreeStats(score: score, plays: plays)
        let node = TreeNode(stats: stats, explorable: true)
        return .Leaf(node)
    }

    @warn_unused_result()
    static func initialTreeForGame(game: G) -> Tree {
        let evaluation = game.evaluate()
        let node: TreeNode
        if evaluation.isFinal {
            let delta = MonteCarloTreeSearch.evaluationAsDelta(evaluation)
            let stats = TreeStats(score: delta, plays: 1)
            node = TreeNode(stats: stats, explorable: false)
        } else {
            let stats = TreeStats(score: 0, plays: 0)
            node = TreeNode(stats: stats, explorable: true)
        }
        return .Leaf(node)
    }

    @warn_unused_result()
    static func evaluationAsDelta(evaluation: Evaluation<Game.Score>) -> Int {
        switch evaluation {
        case .Victory:
            return 1
        case .Defeat:
            return 0
        default:
            return 0
        }
    }

    typealias Node = TreeNode
    typealias Edges = [Game.Move: Tree]

    func isExplorableTree(tree: Tree) -> Bool {
        switch tree {
        case let .Branch(node, _): return node.explorable
        default: return false
        }
    }

    @warn_unused_result()
    static func mergeNodes(lhs: Node, _ rhs: Node) -> Node {
        let stats = lhs.stats.averageWith(rhs.stats)
        let explorable = lhs.explorable && rhs.explorable
        return Node(stats: stats, explorable: explorable)
    }

    @warn_unused_result()
    static func mergeEdges(lhs: Edges, _ rhs: Edges) -> Edges {
        var edges = lhs
        for (move, rhsSubtree) in rhs {
            if let lhsSubtree = edges[move] {
                edges[move] = mergeTrees(lhs: lhsSubtree, rhs: rhsSubtree)
            } else {
                edges[move] = rhsSubtree
            }
        }
        return edges
    }

    @warn_unused_result()
    static func mergeTrees(lhs lhs: Tree, rhs: Tree) -> Tree {
        switch (lhs, rhs) {
        case let (.Leaf(lhsNode), .Leaf(rhsNode)):
            let node = mergeNodes(lhsNode, rhsNode)
            return .Leaf(node)
        case let (.Leaf(lhsNode), .Branch(rhsNode, rhsEdges)):
            let node = mergeNodes(lhsNode, rhsNode)
            return .Branch(node, rhsEdges)
        case let (.Branch(lhsNode, lhsEdges), .Leaf(rhsNode)):
            let node = mergeNodes(lhsNode, rhsNode)
            return .Branch(node, lhsEdges)
        case let (.Branch(lhsNode, lhsEdges), .Branch(rhsNode, rhsEdges)):
            let node = mergeNodes(lhsNode, rhsNode)
            let edges = mergeEdges(lhsEdges, rhsEdges)
            return .Branch(node, edges)
        }
    }
}

extension MonteCarloTreeSearch: CustomDebugStringConvertible {
    public var debugDescription: String {
        return self.tree.debugDescription
    }
}

public struct TreeStats {
    public var score: Int
    public var plays: Int

    init(score: Int, plays: Int) {
        self.score = score
        self.plays = plays
    }

    func averageWith(other: TreeStats) -> TreeStats {
        let score = (self.score + other.score + 1) / 2
        let plays = (self.plays + other.plays + 1) / 2
        return TreeStats(score: score, plays: plays)
    }
}

func +(lhs: TreeStats, rhs: TreeStats) -> TreeStats {
    return TreeStats(score: lhs.score + rhs.score, plays: lhs.plays + rhs.plays)
}

func -(lhs: TreeStats, rhs: TreeStats) -> TreeStats {
    return TreeStats(score: lhs.score - rhs.score, plays: lhs.plays - rhs.plays)
}

func +=(inout lhs: TreeStats, rhs: TreeStats) {
    lhs.score += rhs.score
    lhs.plays += rhs.plays
}

func -=(inout lhs: TreeStats, rhs: TreeStats) {
    lhs.score -= rhs.score
    lhs.plays -= rhs.plays
}

extension TreeStats: CustomStringConvertible {
    public var description: String {
        return "\(self.score) / \(self.plays)"
    }
}

struct TreeNode {
    var stats: TreeStats
    var explorable: Bool

    init(stats: TreeStats, explorable: Bool) {
        self.stats = stats
        self.explorable = explorable
    }
}

extension MonteCarloTreeSearch: Strategy {
    public typealias Game = G

    public func evaluatedMoves(game: Game) -> AnySequence<(G.Move, Evaluation<Game.Score>)> {
        assert(game == self.game)
        assert(game.currentPlayer == self.player)
        let player = game.currentPlayer
        let (node, edges) = self.tree.analysis(leaf: { ($0, [:]) }, branch: { ($0, $1) })
        let n = node.stats.plays
        let moves = game.availableMoves()
        let filteredMoves = policy.filterMoves(game, depth: 0, moves: moves)
        return AnySequence(filteredMoves.lazy.map { move in
            if let subtree = edges[move] {
                let nextGame = game.update(move)
                let evaluation = nextGame.evaluate(forPlayer: player)
                switch evaluation {
                case .Ongoing(_):
                    let subnode = subtree.analysis(leaf: { node in node }, branch: { node, _ in node })
                    let score = self.policy.explorationHeuristic(subnode.stats, n: n)
                    return (move, .Ongoing(score))
                default:
                    return (move, evaluation)
                }
            } else {
                return (move, .Ongoing(Game.Score.mid))
            }
        })
    }
}

struct MonteCarloPayload<G: Game> {
    let game: G
    let randomSource: RandomSource
    let explorationDepth: Int

    init(game: G, randomSource: RandomSource, explorationDepth: Int = 0) {
        self.game = game
        self.randomSource = randomSource
        self.explorationDepth = explorationDepth
    }
}
