//
//  BorderOverlay.swift
//  RLS
//
//  Created by Patrick Wang on 8/6/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//
import Foundation
import MapKit
import UIKit

class BorderOverlay: MKPolygon {
    private var color: UIColor
    
    convenience init(bp: [BorderPoint]) {
        var truncatedCoords: [CLLocationCoordinate2D] = []
        
        //truncate everything
        let math = SpecMath()
        
        for i in 0..<bp.count {
            let coord = bp[i].getCoordinate()
            let truncatedCoord = CLLocationCoordinate2D(latitude: math.truncate(num: coord.latitude), longitude: math.truncate(num: coord.longitude))
            truncatedCoords.append(truncatedCoord)
        }
        
        self.init(coordinates: truncatedCoords, count: truncatedCoords.count)
        self.color = UIColor.black
        //self.vertices = [CLLocationCoordinate2D(latitude: 200, longitude: 200)]
    }
    
    override init() {
        self.color = UIColor.black
        super.init()
    }
    
    func setColor(color: UIColor) {
        self.color = color
    }
    
    func getColor() -> UIColor {
        return self.color
    }
    
    private func loc(lat: CLLocationDegrees, long: CLLocationDegrees) -> CLLocation {
        return CLLocation(latitude: lat, longitude: long)
    }
}
