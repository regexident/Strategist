//
//  Evaluation.swift
//  Strategist
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

public enum Evaluation<T: Score> {
    /// Evaluation of a victory with additional score value
    case Victory(T)
    /// Evaluation of a defeat with additional score value
    case Defeat(T)
    /// Evaluation of a draw additional score value
    case Draw(T)
    /// Evaluation of an ongoing game with additional score value
    case Ongoing(T)

    /// Checks whether `self` is a not ongoing.
    ///
    /// - returns: `false` iff `self` is `.Ongoing(_)`, otherwise `true`
    public var isFinal: Bool {
        switch self {
        case .Ongoing(_): return false
        default: return true
        }
    }

    /// Checks whether `self` is a victory.
    ///
    /// - returns: `true` iff `self` is `.Victory(_)`, otherwise `false`
    public var isVictory: Bool {
        switch self {
        case .Victory(_): return true
        default: return false
        }
    }

    /// Checks whether `self` is a defeat.
    ///
    /// - returns: `true` iff `self` is `.Defeat(_)`, otherwise `false`
    public var isDefeat: Bool {
        switch self {
        case .Defeat(_): return true
        default: return false
        }
    }

    /// Checks whether `self` is a draw.
    ///
    /// - returns: `true` iff `self` is `.Draw(_)`, otherwise `false`
    public var isDraw: Bool {
        switch self {
        case .Draw(_): return true
        default: return false
        }
    }

    /// Inverses `self` by swapping `.Victory()` with `.Defeat()` and the value (in all cases).
    ///
    /// - returns: `.Victory(-v)` iff `self` is `.Defeat(v)` and vice versa, otherwise `.Draw|Ongoing(-v)`
    public func inverse() -> Evaluation {
        switch self {
        case let .Victory(value): return .Defeat(value.inverse())
        case let .Defeat(value): return .Victory(value.inverse())
        case let .Draw(value): return .Draw(value.inverse())
        case let .Ongoing(value): return .Ongoing(value.inverse())
        }
    }

    /// The worst possible evaluation
    /// 
    /// - returns: `.Defeat(-Double.infinity)`
    public static var min: Evaluation {
        return .Defeat(T.min)
    }
    /// The best possible evaluation
    ///
    /// - returns: `.Victory(Double.infinity)`
    public static var max: Evaluation {
        return .Victory(T.max)
    }
}

extension Evaluation : Equatable {}

public func ==<T: Score>(lhs: Evaluation<T>, rhs: Evaluation<T>) -> Bool {
    switch (lhs, rhs) {
    case (.Victory, .Victory): return true
    case (.Defeat, .Defeat): return true
    case (.Draw, .Draw): return true
    case let (.Ongoing(l), .Ongoing(r)): return l == r
    default: return false
    }
}

extension Evaluation : Comparable {}

public func <<T: Score>(lhs: Evaluation<T>, rhs: Evaluation<T>) -> Bool {
    switch (lhs, rhs) {
    case let (.Defeat(l), .Defeat(r)): return l < r
    case let (.Ongoing(l), .Ongoing(r)): return l < r
    case let (.Victory(l), .Victory(r)): return l < r
    case (.Defeat(_), _): return true
    case (_, .Victory(_)): return true
    default: return false
    }
}
