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
    private var lastShadowDate: Date
    let visionDist: Double = 20 //meters
    let math = SpecMath()
    
    init (name: String) {
        self.name = name
        self.team = "none"
        self.dead = false
        self.connected = true
        self.lastShadowDate = Date()
        super.init()
        self.title = name
        let coord = CLLocationCoordinate2D(latitude: 200, longitude: 200)
        self.coordinate = coord
    }
    
    func setCoordinate(coordinate: CLLocationCoordinate2D) -> Void {
        let truncatedCoord = CLLocationCoordinate2D(latitude: math.truncate(num: coordinate.latitude), longitude: math.truncate(num: coordinate.longitude))
        self.coordinate = truncatedCoord
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
    
    func getDead() -> Bool {
        return dead
    }
    
    func setDead(dead: Bool) {
        self.dead = dead
    }
    
    func getConnected() -> Bool {
        return connected
    }
    
    func setConnected(connected: Bool) {
        self.connected = connected
    }
    
    func getLastShadowDate() -> Date {
        return lastShadowDate
    }
    
    func setLastShadowDate(lastShadowDate: Date) {
        self.lastShadowDate = lastShadowDate
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
    }
    
    func getWard() -> Ward? {
        return ward
    }
}
