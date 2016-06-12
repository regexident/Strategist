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
public struct MonteCarloTreeSearch<G, P where G: Game, P: MonteCarloTreeSearchPolicy, P.Game == G, P.Score == G.Score> {

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
        var refinedEdges = edges
        var refinedNode = node
        refinedNode.explorable = unexploredMoves.count > 1
        let chosenMove = self.policy.simulationMove(
            unexploredMoves.generate(),
            simulationDepth: 0,
            randomSource: payload.randomSource
        )
        guard let move = chosenMove else {
            return .Branch(refinedNode, refinedEdges)
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
            refinedEdges[move] = refinedSubtree
        }
        return .Branch(refinedNode, refinedEdges)
    }

    @warn_unused_result()
    func refineExploredSubtree(node: TreeNode, edges: [G.Move: Tree], payload: MonteCarloPayload<G>) -> Tree {
        let plays = node.stats.plays
        var edgesGenerator = edges.generate()
        let generator: AnyGenerator<(G.Move, TreeStats)> = AnyGenerator {
            return edgesGenerator.next().map { move, subtree in
                return (move, subtree.node.stats)
            }
        }
        guard let move = self.policy.explorationMove(generator, explorationDepth: payload.explorationDepth, plays: plays, randomSource: payload.randomSource) else {
            return .Branch(node, edges)
        }
        guard let subtree = edges[move] else {
            return .Branch(node, edges)
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
        var refinedEdges = edges
        refinedEdges[move] = refinedSubtree
        return .Branch(refinedNode, refinedEdges)
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
                let availableMoves = game.availableMoves()
                let choice = self.policy.simulationMove(availableMoves, simulationDepth: simulationDepth, randomSource: payload.randomSource)
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
    public var wins: Int
    public var plays: Int

    init(score: Int, plays: Int) {
        self.wins = score
        self.plays = plays
    }

    func averageWith(other: TreeStats) -> TreeStats {
        let score = (self.wins + other.wins + 1) / 2
        let plays = (self.plays + other.plays + 1) / 2
        return TreeStats(score: score, plays: plays)
    }
}

func +(lhs: TreeStats, rhs: TreeStats) -> TreeStats {
    return TreeStats(score: lhs.wins + rhs.wins, plays: lhs.plays + rhs.plays)
}

func -(lhs: TreeStats, rhs: TreeStats) -> TreeStats {
    return TreeStats(score: lhs.wins - rhs.wins, plays: lhs.plays - rhs.plays)
}

func +=(inout lhs: TreeStats, rhs: TreeStats) {
    lhs.wins += rhs.wins
    lhs.plays += rhs.plays
}

func -=(inout lhs: TreeStats, rhs: TreeStats) {
    lhs.wins -= rhs.wins
    lhs.plays -= rhs.plays
}

extension TreeStats: CustomStringConvertible {
    public var description: String {
        return "\(self.wins) / \(self.plays)"
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
        let parentPlays = node.stats.plays
        let moves = game.availableMoves()
        let filteredMoves = self.policy.filterMoves(game, depth: 0, moves: moves)
        return AnySequence(filteredMoves.lazy.map { move in
            if let subtree = edges[move] {
                let nextGame = game.update(move)
                let evaluation = nextGame.evaluate(forPlayer: player)
                switch evaluation {
                case .Ongoing(_):
                    let score = self.policy.scoreMove(subtree.node.stats, parentPlays: parentPlays)
                    return (move, Evaluation.Ongoing(score))
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
