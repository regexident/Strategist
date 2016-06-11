//
//  Extensions.swift
//  Strategist
//
//  Created by Vincent Esche on 08/06/16.
//  Copyright © 2016 Vincent Esche. All rights reserved.
//

import Darwin

extension GeneratorType {
    func take(upperBound: Int) -> Take<Self> {
        return Take(base: self, upperBound: upperBound)
    }
}

struct Take<G: GeneratorType>: GeneratorType {
    typealias Base = G
    typealias Element = Base.Element

    var base: Base
    var upperBound: Int

    init(base: Base, upperBound: Int) {
        self.base = base
        self.upperBound = upperBound
    }

    mutating func next() -> Element? {
        guard self.upperBound > 0 else {
            return nil
        }
        self.upperBound -= 1
        return self.base.next()
    }
}