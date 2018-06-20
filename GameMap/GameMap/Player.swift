//
//  Player.swift
//  RLS
//
//  Created by Ethan Soo on 4/22/18.
//  Copyright © 2018 Hackathon Event. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class Player: NSObject, MKAnnotation {
    var name: String?
    var team: String
    var id: Double
    var coordinate: CLLocationCoordinate2D
    init(name:String,team:String,id:Double,coordinate:CLLocationCoordinate2D){
        self.name=name
        self.team=team
        self.id=id
        self.coordinate=coordinate
    }
    
    func setCoordinate(coordinate: CLLocationCoordinate2D) -> Void {
        self.coordinate=coordinate
    }
    
    var subtitle: String? {
        return team
    }
}

