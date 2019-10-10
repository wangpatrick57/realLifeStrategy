//
//  Boord.swift
//  RLS
//
//  Created by Patrick Wang on 10/5/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//

import Foundation
import MapKit

class BorderPoint {
    var coord = CLLocationCoordinate2D(latitude: 200, longitude: 200)
    let math = SpecMath()
    
    init(coord: CLLocationCoordinate2D) {
        self.coord = CLLocationCoordinate2D(latitude: math.truncate(num: coord.latitude), longitude: math.truncate(num: coord.longitude))
    }
    
    init(lat: CLLocationDegrees, long: CLLocationDegrees) {
        self.coord = CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
    
    func getCoord() -> CLLocationCoordinate2D {
        return coord
    }
}

