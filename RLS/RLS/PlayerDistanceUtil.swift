//
//  PlayerDistanceUtil.swift
//  RLS
//
//  Created by Ethan Soo on 5/8/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//

import Foundation

class PlayerDistanceUtil {
    
    static func getDistance(_playerX: Player, _playerY: Player) -> Double{
        let latDifference: Double = _playerX.getCoordinate().latitude - _playerY.getCoordinate().latitude
        let longDifference: Double = _playerX.getCoordinate().longitude - _playerY.getCoordinate().longitude
        
        let dist = abs(sqrt(pow(latDifference, 2) + pow(longDifference, 2)))
        
        return dist
    }
    
    static func getClosestPlayer() -> Player{
        return Player()
    }
}
