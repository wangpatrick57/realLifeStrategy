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
    private var circleOverlay: ColorCircleOverlay? = nil
    private var index: Int = -1
    private var name: String = ""
    
    override init() {
        super.init()
        self.coordinate = coordinate
    }
    
    init(index: Int, coordinate:CLLocationCoordinate2D){
        super.init()
        self.index = index
        self.name = "Point \(self.index)"
        self.title = self.name
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
        return coordinate
    }
    
    func getName() -> String {
        return name
    }
}
