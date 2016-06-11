//
//  Score.swift
//  Strategist
//
//  Created by Vincent Esche on 11/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

public protocol Score: Comparable {
    static var min: Self { get }
    static var mid: Self { get }
    static var max: Self { get }
    func inverse() -> Self
}

extension Float: Score {
    public static var min: Float { return -infinity }
    public static var mid: Float { return 0.0 }
    public static var max: Float { return infinity }
    public func inverse() -> Float { return -self }
}

extension Double: Score {
    public static var min: Double { return -infinity }
    public static var mid: Double { return 0.0 }
    public static var max: Double { return infinity }
    public func inverse() -> Double { return -self }
}

extension Int: Score {
    public static var mid: Int { return 0 }
    public func inverse() -> Int { return -self }
}