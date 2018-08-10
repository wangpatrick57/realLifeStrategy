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
    var name: String?
    var team: String
    var id: Double

    init(name:String,team:String,id:Double,coordinates:CLLocationCoordinate2D){
        self.name=name
        self.team=team
        self.id=id
        super.init()
        self.coordinate=coordinates
    }
    
    func setCoordinate(coordinate: CLLocationCoordinate2D) -> Void {
        self.coordinate=coordinate
    }
    func getCoordinate()->CLLocationCoordinate2D {
        return self.coordinate
    }
    /*
    var subtitle: String? {
        return team
    }*/
}

