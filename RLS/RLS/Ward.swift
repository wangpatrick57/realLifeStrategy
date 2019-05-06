//
//  Ward.swift
//  RLS
//
//  Created by Patrick Wang on 5/4/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class Ward: MKPointAnnotation{
    private var name: String
    private var team: String
    let visionDist: Double = 30 //meters
    
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
    
    func setTeam(team: String) {
        self.team = team
    }
    
    func getTeam() -> String {
        return team
    }
}
