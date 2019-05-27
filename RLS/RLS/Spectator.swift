//
//  Spectator.swift
//  RLS
//
//  Created by Melody Lee on 5/25/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//

import Foundation
import MapKit

class Spectator: Player {
    
    override init(){
        super.init()
        setTeam(team: "neutral")
    }
    
    init(name: String, team: String, coordinate: CLLocationCoordinate2D) {
        super.init(name: name, team: team, coordinate: coordinate)
        setTeam(team: "neutral")
    }
    
    //never dies
    override func setDead(dead: Bool) {
    }
}
