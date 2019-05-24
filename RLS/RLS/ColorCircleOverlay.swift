//
//  ColorCircleOverlay.swift
//  RLS
//
//  Created by Jordan Chew on 5/24/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//

import Foundation
import MapKit
import UIKit

class ColorCircleOverlay: MKCircle{
    var color: UIColor
    
    convenience init(annotation: MKAnnotation, radius: CLLocationDistance, color: UIColor){
        self.init(center: annotation.coordinate, radius: radius)
        self.color = color
    }
    
    override init() {
        self.color = UIColor.black
        super.init()
    }
    
}

