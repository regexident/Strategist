//
//  Evaluation.swift
//  Strategist
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

/// Game state evaluation
public enum Evaluation<T: Score> {
    /// Evaluation of a victory with additional score value
    case victory(T)
    /// Evaluation of a defeat with additional score value
    case defeat(T)
    /// Evaluation of a draw additional score value
    case draw(T)
    /// Evaluation of an ongoing game with additional score value
    case ongoing(T)

    /// Checks whether `self` is a not ongoing.
    ///
    /// - returns: `false` iff `self` is `.Ongoing(_)`, otherwise `true`
    public var isFinal: Bool {
        switch self {
        case .ongoing(_): return false
        default: return true
        }
    }

    /// Checks whether `self` is a victory.
    ///
    /// - returns: `true` iff `self` is `.Victory(_)`, otherwise `false`
    public var isVictory: Bool {
        switch self {
        case .victory(_): return true
        default: return false
        }
    }

    /// Checks whether `self` is a defeat.
    ///
    /// - returns: `true` iff `self` is `.Defeat(_)`, otherwise `false`
    public var isDefeat: Bool {
        switch self {
        case .defeat(_): return true
        default: return false
        }
    }

    /// Checks whether `self` is a draw.
    ///
    /// - returns: `true` iff `self` is `.Draw(_)`, otherwise `false`
    public var isDraw: Bool {
        switch self {
        case .draw(_): return true
        default: return false
        }
    }

    /// Inverses `self` by swapping `.Victory()` with `.Defeat()` and the value (in all cases).
    ///
    /// - returns: `.Victory(-v)` iff `self` is `.Defeat(v)` and vice versa, otherwise `.Draw|Ongoing(-v)`
    public func inverse() -> Evaluation {
        switch self {
        case let .victory(value): return .defeat(value.inverse())
        case let .defeat(value): return .victory(value.inverse())
        case let .draw(value): return .draw(value.inverse())
        case let .ongoing(value): return .ongoing(value.inverse())
        }
    }

    /// The worst possible evaluation
    /// 
    /// - returns: `.Defeat(-Double.infinity)`
    public static var min: Evaluation {
        return .defeat(T.min)
    }
    /// The best possible evaluation
    ///
    /// - returns: `.Victory(Double.infinity)`
    public static var max: Evaluation {
        return .victory(T.max)
    }
}

extension Evaluation : Equatable {}

public func ==<T>(lhs: Evaluation<T>, rhs: Evaluation<T>) -> Bool {
    switch (lhs, rhs) {
    case (.victory, .victory): return true
    case (.defeat, .defeat): return true
    case (.draw, .draw): return true
    case let (.ongoing(l), .ongoing(r)): return l == r
    default: return false
    }
}

extension Evaluation : Comparable {}

public func <<T>(lhs: Evaluation<T>, rhs: Evaluation<T>) -> Bool {
    switch (lhs, rhs) {
    case let (.defeat(l), .defeat(r)): return l < r
    case let (.ongoing(l), .ongoing(r)): return l < r
    case let (.victory(l), .victory(r)): return l < r
    case (.defeat(_), _): return true
    case (_, .victory(_)): return true
    default: return false
    }
}
