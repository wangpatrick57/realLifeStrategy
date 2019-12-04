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
    var coordinate = CLLocationCoordinate2D(latitude: 200, longitude: 200)
    let math = SpecMath()
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = CLLocationCoordinate2D(latitude: math.truncate(num: coordinate.latitude), longitude: math.truncate(num: coordinate.longitude))
    }
    
    init(lat: CLLocationDegrees, long: CLLocationDegrees) {
        self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
    
    func getCoordinate() -> CLLocationCoordinate2D {
        return coordinate
    }
}

