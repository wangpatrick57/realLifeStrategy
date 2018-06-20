//
//  Player.swift
//  rls
//
//  Created by Ethan Soo on 4/21/18.
//  Copyright © 2018 Ethan Soo. All rights reserved.
//

import Foundation
class Player {
    var playerName:String
    var longitude:Double
    var latitude:Double
    var id:Int
    var active:Bool
    init(name:String, long:Double, lat:Double) {
        playerName = name
        longitude = long
        latitude = lat
        id = 0
        active = true
    }
    
    func description() -> String {
        let player: String = "\(id)  \(playerName)"
        let coords: String = "( \(longitude) , \(latitude) )"
        return player + "  " + coords
    }
}
