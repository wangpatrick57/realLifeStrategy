//
//  SpecMath.swift
//  RLS
//
//  Created by Patrick Wang on 10/5/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//

import Foundation

class SpecMath {
    var truncPlaces = 5
    
    func truncate(num: Double) -> Double {
        return Double(round(pow(10.0, Double(truncPlaces)) * num) / pow(10.0, Double(truncPlaces)))
    }
}
