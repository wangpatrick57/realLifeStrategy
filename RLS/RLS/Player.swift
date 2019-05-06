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
    private var name: String
    private var team: String
    private var ward: Ward?
    let visionDist: Double = 20 //meters
    
    override init() {
        self.name = ""
        self.team = ""
        super.init()
        self.title = self.name
        self.coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
    
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
    
    func addWard() {
        ward = Ward(name: name + "'s ward", team: team, coordinate: coordinate)
    }
    
    func addWardAt(coordinate: CLLocationCoordinate2D) {
        ward = Ward(name: name + "'s ward", team: team, coordinate: coordinate)
    }
    
    func getWard() -> Ward? {
        return ward
    }
}
