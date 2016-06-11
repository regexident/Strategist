//
//  RandomSource.swift
//  Strategist
//
//  Created by Vincent Esche on 06/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

import Darwin

public typealias RandomSource = UInt32 -> UInt32

public func fakeRandomSource(output: UInt32) -> RandomSource {
    return { _ in
        return output
    }
}