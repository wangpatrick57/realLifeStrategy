//
//  Ping.swift
//  RLS
//
//  Created by Patrick Wang on 5/12/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class Ping: MKPointAnnotation {
    var createTime = -1.0
    var lifeTime = 5.0
    var name = ""
    
    init(coordinate: CLLocationCoordinate2D, name: String, createTime: Double) {
        super.init()
        self.coordinate = coordinate
        self.title = name
        self.createTime = createTime
    }
    
    func checkDead() -> Bool {
        if (CACurrentMediaTime() > createTime + lifeTime) {
            return true
        }
        
        return false
    }
}
