//
//  ViewCircleOverlay.swift
//  RLS
//
//  Created by Jordan Chew on 5/16/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//

import Foundation
import MapKit
import UIKit

class ViewCircleOverlay: NSObject, MKOverlay{
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    
    init(annotation: MKAnnotation){
        self.coordinate = annotation.coordinate
        self.boundingMapRect = MKMapRect.init()
    }
}
