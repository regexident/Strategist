//
//  GameTree.swift
//  Strategist
//
//  Created by Vincent Esche on 09/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

/// Generic tree representation with non-uniform branching factor.
public indirect enum GameTree<Node, Edge: Hashable> {
    /// Leaf tree node
    case leaf(Node)
    /// Branch tree node
    case branch(Node, [Edge: GameTree<Node, Edge>])

    public var node: Node {
        switch self {
        case .leaf(let node):
            return node
        case .branch(let node, _):
            return node
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
    public func analysis<T>(leaf: (Node) -> T, branch: (Node, [Edge: GameTree<Node, Edge>]) -> T) -> T {
        switch self {
        case .leaf(let node):
            return leaf(node)
        case .branch(let node, let edges):
            return branch(node, edges)
        }
    }

    /// Generate dot-formatted ([Graphviz](http://graphviz.org/)) tree representation.
    public func customDebugDescription(_ tree: GameTree<Node, Edge>, parentEdge: Edge? = nil, prefix: String = "root", closure: (Node, Edge?) -> (String, String?)) -> String {
        var string = ""
        if parentEdge == nil {
            string += "digraph GameTree {"
        }
        let (node, edges) = self.analysis(leaf: { ($0, [:]) }, branch: { ($0, $1) })
        let (nodeLabel, edgeLabel) = closure(node, parentEdge)
        let nodeID = prefix
        string += "\t\(nodeID) [label=\"\(nodeLabel)\"];"
        for (index, (key: edge, value: subtree)) in edges.enumerated() {
            let subnodeID = nodeID + "_\(index)"
            string += self.customDebugDescription(subtree, parentEdge: edge, prefix: subnodeID, closure: closure)
            string += "\t\(nodeID) -> \(subnodeID) [label=\"\(edgeLabel ?? "<null>")\"];"
        }
        if parentEdge == nil {
            string += "}"
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

extension GameTree: CustomDebugStringConvertible {
    public var debugDescription: String {
        return self.customDebugDescription(self) { node, edge in
            let nodeLabel = "\(node)"
            let edgeLabel = edge.map { "\($0)" }
            return (nodeLabel, edgeLabel)
        }
    }
}
