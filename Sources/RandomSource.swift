//
//  RandomSource.swift
//  Strategist
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

import Darwin

/// Function type used for injecting random sources into Strategist.
public typealias RandomSource = UInt32 -> UInt32

/// Convenience function for generating curried fake random sources.
public func fakeRandomSource(output: UInt32) -> RandomSource {
    return { upperBound in
        assert(output < upperBound)
        return output
    }
}