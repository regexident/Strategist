//
//  GameTree.swift
//  Strategist
//
//  Created by Vincent Esche on 09/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

/// Generic tree representation with non-uniform branching factor.
public indirect enum GameTree<Node, Edge> where Edge: Hashable {
    public typealias Branches = TreeBranches<Edge, Node>

    /// Leaf tree node
    case leaf(Node)
    /// Branch tree node
    case branch(Node, Branches)

    public var node: Node {
        switch self {
        case .leaf(let node):
            return node
        case .branch(let node, _):
            return node
        }
    }

    public func height() -> Int {
        switch self {
        case .leaf(_):
            return 0
        case .branch(_, let edges):
            return 1 + edges.subtrees.reduce(0) { max($0, $1.height()) }
        }
    }

    public mutating func mergeWith(
        _ other: Self,
        nodes mergeNodes: (inout Node, Node) -> (),
        edges mergeBranches: (inout Branches, Branches) -> ()
    ) {
        switch (self, other) {
        case let (.leaf(lhsNode), .leaf(rhsNode)):
            var node = lhsNode
            mergeNodes(&node, rhsNode)
            self = .leaf(node)
        case let (.leaf(lhsNode), .branch(rhsNode, rhsBranches)):
            var node = lhsNode
            mergeNodes(&node, rhsNode)
            self = .branch(node, rhsBranches)
        case let (.branch(lhsNode, lhsBranches), .leaf(rhsNode)):
            var node = lhsNode
            mergeNodes(&node, rhsNode)
            self = .branch(node, lhsBranches)
        case let (.branch(lhsNode, lhsBranches), .branch(rhsNode, rhsBranches)):
            var node = lhsNode
            mergeNodes(&node, rhsNode)
            var edges = lhsBranches
            mergeBranches(&edges, rhsBranches)
            self = .branch(node, edges)
        }
    }

    /// Execute passed closures based on node type.
    ///
    /// Implemented as:
    /// ```
    /// switch self {
    /// case .Leaf(let node):
    ///     return leaf(node)
    /// case .Branch(let node, let edges):
    ///     return branch(node, edges)
    /// }
    /// ```
    public func analysis<T>(leaf: (Node) -> T, branch: (Node, TreeBranches<Edge, Node>) -> T) -> T {
        switch self {
        case .leaf(let node):
            return leaf(node)
        case .branch(let node, let edges):
            return branch(node, edges)
        }
    }

    /// Generate dot-formatted ([Graphviz](http://graphviz.org/)) tree representation.
    public static func customDebugDescription(
        _ tree: GameTree<Node, Edge>,
        parentEdge: Edge? = nil,
        prefix: String = "root",
        closure: (Node, Edge?) -> (String, String?)
    ) -> String {
        var string = ""
        if parentEdge == nil {
            string += "digraph GameTree {\n"
        }
        let (node, edges) = tree.analysis(leaf: { ($0, [:]) }, branch: { ($0, $1) })
        let (nodeLabel, edgeLabel) = closure(node, parentEdge)
        let nodeID = prefix
        string += "\t\(nodeID) [label=\"\(nodeLabel)\"];\n"
        for (index, (key: edge, value: subtree)) in edges.enumerated() {
            let subnodeID = nodeID + "_\(index)"
            string += Self.customDebugDescription(subtree, parentEdge: edge, prefix: subnodeID, closure: closure)
            string += "\t\(nodeID) -> \(subnodeID) [label=\"\(edgeLabel ?? "<null>")\"];\n"
        }
        if parentEdge == nil {
            string += "}\n"
        }
        return string
    }
}

extension GameTree: CustomStringConvertible {
    public var description: String {
        switch self {
        case .leaf(let node):
            return ".Leaf(\(node))"
        case .branch(let node, let edges):
            let edges = edges.map { edge, _ in edge }
            return ".Branch(\(node), \(edges))"
        }
    }
}

extension GameTree: CustomDebugStringConvertible
where
    Node: CustomDebugStringConvertible,
    Edge: CustomDebugStringConvertible
{
    public var debugDescription: String {
        return Self.customDebugDescription(self) { node, edge in
            let nodeLabel = node.debugDescription
            let edgeLabel = edge.map { $0.debugDescription }
            return (nodeLabel, edgeLabel)
        }
    }
}

public struct TreeBranches<Edge, Node> where Edge: Hashable {
    public typealias Key = Edge
    public typealias Value = Subtree
    public typealias Storage = Dictionary<Key, Value>

    public typealias Subtree = GameTree<Node, Edge>

    public typealias Edges = Storage.Keys
    public typealias Subtrees = Storage.Values

    private var storage: Storage

    public var edges: Edges {
        self.storage.keys
    }

    public var subtrees: Subtrees {
        self.storage.values
    }

    mutating func mergeWith(
        _ other: Self,
        nodes mergeNodes: (inout Node, Node) -> (),
        edges mergeBranches: (inout Self, Self) -> ()
    ) {
        for (move, rhsSubtree) in other.storage {
            var subtree: Subtree
            if let lhsSubtree = self.storage[move] {
                subtree = lhsSubtree
                subtree.mergeWith(rhsSubtree, nodes: mergeNodes, edges: mergeBranches)
            } else {
                subtree = rhsSubtree
            }
            self.storage[move] = subtree
        }
    }
}

extension TreeBranches: Collection {
    public typealias Element = Storage.Element
    public typealias Index = Storage.Index

    public var startIndex: Index {
        self.storage.startIndex
    }

    public var endIndex: Index {
        self.storage.endIndex
    }

    public func index(after index: Index) -> Index {
        self.storage.index(after: index)
    }

    public subscript(position: Index) -> Element {
        self.storage[position]
    }

    subscript(key: Key) -> Value? {
        get {
            return self.storage[key]
        }
        set {
            self.storage[key] = newValue
        }
    }
}

extension TreeBranches: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (Edge, Subtree)...) {
        self.storage = Dictionary(uniqueKeysWithValues: elements)
    }
}
