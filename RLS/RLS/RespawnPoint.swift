//
//  RespawnPoint.swift
//  RLS
//
//  Created by Patrick Wang on 5/17/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class RespawnPoint: MKPointAnnotation{
    private var name: String
    
    override init() {
        self.name = ""
        super.init()
        self.title = name
        self.coordinate = coordinate
    }
    
    init(name:String,coordinate:CLLocationCoordinate2D){
        self.name=name
        super.init()
        self.title = name
        self.coordinate = coordinate
    }
    
    func setCoordinate(coordinate: CLLocationCoordinate2D) -> Void {
        self.coordinate=coordinate
    }
    
    func getCoordinate()->CLLocationCoordinate2D {
        return self.coordinate
    }
    
    func getName() -> String {
        return name
    }
}
