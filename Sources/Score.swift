//
//  Score.swift
//  Strategist
//
//  Created by Vincent Esche on 11/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

/// Score protocol used for scores of game state evaluations.
public protocol Score: Comparable {
    /// Smallest possible evaluation score.
    static var min: Self { get }
    /// Neutral evaluation score.
    static var mid: Self { get }
    /// Largest possible evaluation score.
    static var max: Self { get }

    /// Invert evaluation score.
    ///
    /// - returns: Inverted evaluation score
    func inverse() -> Self
}

extension Double: Score {
    public static var min: Double { return -.infinity }
    public static var mid: Double { return 0.0 }
    public static var max: Double { return .infinity }
    public func inverse() -> Double { return -self }
}

extension Float: Score {
    public static var min: Float { return -.infinity }
    public static var mid: Float { return 0.0 }
    public static var max: Float { return .infinity }
    public func inverse() -> Float { return -self }
}

extension Int: Score {
    public static var mid: Int { return 0 }
    public func inverse() -> Int { return -self }
}

extension UInt: Score {
    public static var mid: UInt { return .max / 2 }
    public func inverse() -> UInt { return .max - self }
}

extension Int64: Score {
    public static var mid: Int64 { return 0 }
    public func inverse() -> Int64 { return -self }
}

extension UInt64: Score {
    public static var mid: UInt64 { return .max / 2 }
    public func inverse() -> UInt64 { return .max - self }
}

extension Int32: Score {
    public static var mid: Int32 { return 0 }
    public func inverse() -> Int32 { return -self }
}

extension UInt32: Score {
    public static var mid: UInt32 { return .max / 2 }
    public func inverse() -> UInt32 { return .max - self }
}

extension Int16: Score {
    public static var mid: Int16 { return 0 }
    public func inverse() -> Int16 { return -self }
}

extension UInt16: Score {
    public static var mid: UInt16 { return .max / 2 }
    public func inverse() -> UInt16 { return .max - self }
}

extension Int8: Score {
    public static var mid: Int8 { return 0 }
    public func inverse() -> Int8 { return -self }
}

extension UInt8: Score {
    public static var mid: UInt8 { return .max / 2 }
    public func inverse() -> UInt8 { return .max - self }
}
