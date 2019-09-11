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
    private var dead: Bool
    private var connected: Bool
    let visionDist: Double = 20 //meters
    
    init (name: String) {
        self.name = name
        self.team = "none"
        self.dead = false
        self.connected = true
        super.init()
        self.title = name
        let coord = CLLocationCoordinate2D(latitude: 200, longitude: 200)
        self.coordinate = coord
        //these two because dead and connected have default values
        networking.setSendDead(sd: true)
        networking.setSendConn(sc: true)
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
        networking.setSendTeam(st: true)
    }
    
    func getTeam() -> String {
        return team
    }
    
    func getDead() -> Bool {
        return dead
    }
    
    func setDead(dead: Bool) {
        self.dead = dead
        networking.setSendDead(sd: true)
    }
    
    func getConnected() -> Bool {
        return connected
    }
    
    func setConnected(connected: Bool) {
        self.connected = connected
        networking.setSendConn(sc: true)
    }
    
    func addWard() {
        addWardAt(coordinate: coordinate)
    }
    
    func addWardAt(coordinate: CLLocationCoordinate2D) {
        if let thisWard = ward {
            thisWard.setCoordinate(coordinate: coordinate)
            thisWard.setTeam(team: team)
        } else {
            ward = Ward(name: name + "'s ward", team: team, coordinate: coordinate)
        }
        
        networking.setSendWard(sw: true)
    }
    
    func getWard() -> Ward? {
        return ward
    }
}
