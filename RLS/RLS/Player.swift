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

class Player: MKPointAnnotation{
    var name: String
    var team: String
    var visionDist: Double = 20 //meters
    
    init(name:String,team:String,coordinate:CLLocationCoordinate2D){
        self.name=name
        self.team=team
        super.init()
        self.title = self.name
        self.coordinate=coordinate
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
    /*
     var subtitle: String? {
     return team
     }*/
}
