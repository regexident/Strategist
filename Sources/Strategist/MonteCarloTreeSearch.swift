//
//  MonteCarloTreeSearch.swift
//  Strategist
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

/// Implementation of [Monte Carlo Tree Search](https://en.wikipedia.org/wiki/Monte_Carlo_tree_search) algorithm.
///
/// - note: Due to internal state a separate instance of `MonteCarloTreeSearch` has to be used for for each player in a game.
public struct MonteCarloTreeSearch<G, P> where P: MonteCarloTreeSearchPolicy, P.Game == G, P.Score == G.Score {
    typealias Tree = Strategist.GameTree<Node, Edge>
    typealias Node = TreeNode
    typealias Edge = G.Move
    typealias Branches = TreeBranches<Edge, Node>

    public var game: G
    public let player: G.Player
    public let policy: P

    var tree: Tree

    public init(game: G, player: G.Player, policy: P) {
        let tree = MonteCarloTreeSearch.initialTreeForGame(game, policy: policy)
        self.init(game: game, player: player, policy: policy, tree: tree)
    }

    init(game: G, player: G.Player, policy: P, tree: Tree) {
        self.game = game
        self.player = player
        self.policy = policy
        self.tree = tree
    }

    public mutating func update(_ move: G.Move) {
        self.game = self.game.update(move)
        self.tree = self.tree.analysis(leaf: { node in
            return MonteCarloTreeSearch.initialTreeForGame(self.game, policy: self.policy)
        }, branch: { node, edges in
            if let index = edges.firstIndex(where: { $0.0 == move }) {
                return edges[index].1
            } else {
                return MonteCarloTreeSearch.initialTreeForGame(self.game, policy: self.policy)
            }
        })
    }
}

extension MonteCarloTreeSearch: Strategy {
    public typealias Game = G

    public func evaluatedMoves(_ game: Game) -> AnySequence<(G.Move, Evaluation<Game.Score>)> {
        assert(game == self.game)
        assert(game.currentPlayer == self.player)

        let player = game.currentPlayer
        let (node, edges) = self.tree.analysis(leaf: { ($0, [:]) }, branch: { ($0, $1) })
        let parentPlays = node.stats.plays
        let moves = game.availableMoves()
        let filteredMoves = self.policy.filterMoves(game, depth: 0, moves: moves)
        return AnySequence(filteredMoves.lazy.map { move in
            if let subtree = edges[move] {
                let nextGame = game.update(move)
                let evaluation = nextGame.evaluate(forPlayer: player)
                switch evaluation {
                case .ongoing(_):
                    let score = self.policy.scoreMove(subtree.node.stats, parentPlays: parentPlays)
                    return (move, Evaluation.ongoing(score))
                default:
                    return (move, evaluation)
                }
            } else {
                return (move, .ongoing(Game.Score.mid))
            }
        })
    }
}

extension MonteCarloTreeSearch: MonteCarloTreeSearchStrategy {
    public mutating func refine(
        using randomSource: @escaping RandomSource = Int.random(in:)
    ) {
        guard self.player == self.game.currentPlayer else {
            return
        }

        let payload = MonteCarloPayload<G>(game: self.game, randomSource: randomSource)
        self.tree = self.refineSubtree(self.tree, payload: payload)
    }

    public mutating func mergeWith(_ other: MonteCarloTreeSearch) {
        assert(self.game == other.game)
        assert(self.player == other.player)

        Self.merge(tree: &self.tree, with: other.tree)
    }
}

extension MonteCarloTreeSearch {
    private func refineSubtree(_ subtree: Tree, payload: MonteCarloPayload<G>) -> Tree {
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
        guard case .branch(var node, let edges) = refinedSubtree, !node.explorable else {
            return refinedSubtree
        }
        guard self.policy.shouldCollapseTree(node.stats, subtrees: edges.count, depth: payload.explorationDepth) else {
            return refinedSubtree
        }
        node.explorable = true
        return .leaf(node)
    }

    private func refineExplorableSubtree(_ node: Node, edges: TreeBranches<G.Move, Node>, payload: MonteCarloPayload<G>) -> Tree {
        let exploredMoves = Set(edges.map { $0.0 })
        let moves = payload.game.availableMoves()
        let filteredMoves = policy.filterMoves(payload.game, depth: payload.explorationDepth, moves: moves)
        let unexploredMoves = filteredMoves.filter { !exploredMoves.contains($0) }
        var refinedBranches = edges
        var refinedNode = node
        refinedNode.explorable = unexploredMoves.count > 1
        let chosenMove = self.policy.simulationMove(
            unexploredMoves.makeIterator(),
            simulationDepth: 0,
            using: payload.randomSource
        )
        guard let move = chosenMove else {
            return .branch(refinedNode, refinedBranches)
        }
        let nextPayload = MonteCarloPayload<G>(
            game: payload.game.update(move),
            randomSource: payload.randomSource,
            explorationDepth: payload.explorationDepth + 1
        )
        let refinedSubtree = self.simulateSubtree(payload.game.currentPlayer, payload: nextPayload)
        let refinedSubnode = refinedSubtree.node
        refinedNode.stats += refinedSubnode.stats
        if !policy.hasReachedMaxExplorationDepth(payload.explorationDepth) {
            refinedBranches[move] = refinedSubtree
        }
        return .branch(refinedNode, refinedBranches)
    }

    private func refineExploredSubtree(_ node: Node, edges: TreeBranches<G.Move, Node>, payload: MonteCarloPayload<G>) -> Tree {
        let plays = node.stats.plays
        var edgesGenerator = edges.makeIterator()
        let generator: AnyIterator<(G.Move, TreeStats)> = AnyIterator {
            return edgesGenerator.next().map { move, subtree in
                return (move, subtree.node.stats)
            }
        }
        guard let move = self.policy.explorationMove(generator, explorationDepth: payload.explorationDepth, plays: plays, using: payload.randomSource) else {
            return .branch(node, edges)
        }
        guard let subtree = edges[move] else {
            return .branch(node, edges)
        }
        var refinedNode = node
        refinedNode.stats -= subtree.node.stats
        let payload = MonteCarloPayload<G>(
            game: payload.game.update(move),
            randomSource: payload.randomSource,
            explorationDepth: payload.explorationDepth + 1
        )
        let refinedSubtree = self.refineSubtree(subtree, payload: payload)
        refinedNode.stats += refinedSubtree.node.stats
        var refinedBranches = edges
        refinedBranches[move] = refinedSubtree
        return .branch(refinedNode, refinedBranches)
    }

    private func simulateSubtree(_ rootPlayer: G.Player, payload: MonteCarloPayload<G>) -> Tree {
        var evaluation = payload.game.evaluate(forPlayer: rootPlayer)
        guard !evaluation.isFinal else {
            let score = self.policy.reward(evaluation)
            let stats = TreeStats(score: score, plays: 1)
            let node = Node(stats: stats, explorable: false)
            return .leaf(node)
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
                let availableMoves = game.availableMoves()
                let choice = self.policy.simulationMove(availableMoves, simulationDepth: simulationDepth, using: payload.randomSource)
                guard let move = choice else {
                    break
                }
                game = game.update(move)
                simulationDepth += 1
            }
            score += self.policy.reward(evaluation)
            plays += 1
        }
        let stats = TreeStats(score: score, plays: plays)
        let node = Node(stats: stats, explorable: true)
        return .leaf(node)
    }

    private static func initialTreeForGame(_ game: G, policy: P) -> Tree {
        let evaluation = game.evaluate()
        let node: Node
        if evaluation.isFinal {
            let delta = policy.reward(evaluation)
            let stats = TreeStats(score: delta, plays: 1)
            node = Node(stats: stats, explorable: false)
        } else {
            let stats = TreeStats(score: 0, plays: 0)
            node = Node(stats: stats, explorable: true)
        }
        return .leaf(node)
    }

    private func isExplorableTree(_ tree: Tree) -> Bool {
        switch tree {
        case let .branch(node, _): return node.explorable
        default: return false
        }
    }

    private static func merge(tree: inout Tree, with other: Tree) {
        tree.mergeWith(
            other,
            nodes: { (node, otherNode) in
                Self.merge(node: &node, with: otherNode)
        	},
            edges: { (edges, otherBranches) in
                Self.merge(edges: &edges, with: otherBranches)
            }
        )
    }

    private static func merge(node: inout Node, with other: Node) {
        node.mergeWith(other)
    }

    private static func merge(edges: inout Tree.Branches, with other: Tree.Branches) {
        for (move, rhsSubtree) in other {
            if let lhsSubtree = edges[move] {
                var tree = lhsSubtree
                Self.merge(tree: &tree, with: lhsSubtree)
                edges[move] = tree
            } else {
                edges[move] = rhsSubtree
            }
        }
    }
}

extension MonteCarloTreeSearch: CustomDebugStringConvertible
where
    G.Move: CustomDebugStringConvertible
{
    public var debugDescription: String {
        return self.tree.debugDescription
    }
}

public struct TreeStats {
    public var wins: Int
    public var plays: Int

    init(score: Int, plays: Int) {
        self.wins = score
        self.plays = plays
    }

    func averageWith(_ other: TreeStats) -> TreeStats {
        let score = (self.wins + other.wins + 1) / 2
        let plays = (self.plays + other.plays + 1) / 2
        return TreeStats(score: score, plays: plays)
    }

    static func +(lhs: Self, rhs: Self) -> Self {
        return TreeStats(score: lhs.wins + rhs.wins, plays: lhs.plays + rhs.plays)
    }

    static func -(lhs: Self, rhs: Self) -> Self {
        return TreeStats(score: lhs.wins - rhs.wins, plays: lhs.plays - rhs.plays)
    }

    static func +=(lhs: inout Self, rhs: Self) {
        lhs.wins += rhs.wins
        lhs.plays += rhs.plays
    }

    static func -=(lhs: inout Self, rhs: Self) {
        lhs.wins -= rhs.wins
        lhs.plays -= rhs.plays
    }
}

extension TreeStats: CustomStringConvertible {
    public var description: String {
        return "\(self.wins) / \(self.plays)"
    }
}

extension TreeStats: CustomDebugStringConvertible {
    public var debugDescription: String {
        return self.description
    }
}

struct TreeNode {
    var stats: TreeStats
    var explorable: Bool

    init(stats: TreeStats, explorable: Bool) {
        self.stats = stats
        self.explorable = explorable
    }

    mutating func mergeWith(_ other: Self) {
        self.stats = self.stats.averageWith(other.stats)
        self.explorable = self.explorable && other.explorable
    }

    func mergedWith(_ other: Self) -> Self {
        var copy = self
        copy.mergeWith(other)
        return copy
    }
}

extension TreeNode: CustomStringConvertible {
    public var description: String {
        var description = self.stats.debugDescription

        if self.explorable {
            description += " | explorable"
        }

        return description
    }
}

extension TreeNode: CustomDebugStringConvertible {
    public var debugDescription: String {
        return self.description
    }
}

struct MonteCarloPayload<G: Game> {
    let game: G
    let randomSource: RandomSource
    let explorationDepth: Int

    init(game: G, randomSource: @escaping RandomSource, explorationDepth: Int = 0) {
        self.game = game
        self.randomSource = randomSource
        self.explorationDepth = explorationDepth
    }
}