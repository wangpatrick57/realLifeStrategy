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
    private var vertices: [CLLocation]
    private var color: UIColor
    
    convenience init(vertices: [CLLocation]) {
        var unsafeVertices = vertices.map({ (location: CLLocation!) -> CLLocationCoordinate2D in return location.coordinate })
        self.init(coordinates: &unsafeVertices, count: vertices.count)
        self.color = UIColor.black
        self.vertices = vertices
        //self.vertices = [CLLocationCoordinate2D(latitude: 200, longitude: 200)]
    }
    
    override init() {
        self.vertices = []
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
