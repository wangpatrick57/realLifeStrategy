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
    private var connected = true
    private var teamChanged: Bool
    let visionDist: Double = 20 //meters
    
    override init() {
        self.name = ""
        self.team = ""
        self.dead = false
        self.teamChanged = false
        super.init()
        self.coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
    
    init(name:String,team:String,coordinate:CLLocationCoordinate2D){
        self.name=name
        self.team=team
        self.dead = false
        self.teamChanged = false
        super.init()
        self.title = name
        //self.subtitle = team
        self.coordinate=coordinate
    }
    
    init(name:String,team:String,coordinate:CLLocationCoordinate2D, dead:Bool){
        self.name=name
        self.team=team
        self.dead = dead
        self.teamChanged = false
        super.init()
        self.title = name
        //self.subtitle = team
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
        if (team != self.team) {
            teamChanged = true
        }
        
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
    
    func getTeamChanged() -> Bool {
        return teamChanged
    }
    
    func setTeamChanged(teamChanged: Bool) {
        self.teamChanged = teamChanged
    }
    
    func addWard() {
        addWardAt(coordinate: coordinate)
    }
    
    func addWardAt(coordinate: CLLocationCoordinate2D) {
        if let myWard = ward {
            myWard.setCoordinate(coordinate: coordinate)
        } else {
            ward = Ward(name: name + "'s ward", team: team, coordinate: coordinate)
        }
    }
    
    func getWard() -> Ward? {
        return ward
    }
}
