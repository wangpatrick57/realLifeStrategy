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
    private var circleOverlay: ColorCircleOverlay? = nil
    
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
        let math = SpecMath()
        let truncatedCoord = CLLocationCoordinate2D(latitude: math.truncate(num: coordinate.latitude), longitude: math.truncate(num: coordinate.longitude))
        self.coordinate = truncatedCoord
    }
    
    func setCoordinate(coordinate: CLLocationCoordinate2D) -> Void {
        let math = SpecMath()
        let truncatedCoord = CLLocationCoordinate2D(latitude: math.truncate(num: coordinate.latitude), longitude: math.truncate(num: coordinate.longitude))
        self.coordinate = truncatedCoord
    }
    
    func setOverlay(overlay: ColorCircleOverlay) {
        circleOverlay = overlay
    }
    
    func getOverlay() -> ColorCircleOverlay? {
        return circleOverlay
    }
    
    func getCoordinate()->CLLocationCoordinate2D {
        return self.coordinate
    }
    
    func getName() -> String {
        return name
    }
}
