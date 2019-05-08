//
//  PlayerDistanceUtil.swift
//  RLS
//
//  Created by Ethan Soo on 5/8/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//

import Foundation

class PlayerDistanceUtil {
    
    //param: player A, player B
    //return distance between both players
    static func getDistance(_ playerX: Player, _ playerY: Player) -> Double{
        let latDifference: Double = playerX.getCoordinate().latitude - playerY.getCoordinate().latitude
        let longDifference: Double = playerX.getCoordinate().longitude - playerY.getCoordinate().longitude
        
        let dist = abs(sqrt(pow(latDifference, 2) + pow(longDifference, 2)))
        
        return dist
    }
    
    //param: main player, list of all players in game
    //return player closest to main player
    static func getClosestPlayer(mainPlayer: Player, playerList: [Player]) -> Player{
        
        var closestDistance: Double = getDistance(mainPlayer, playerList[0])
        var closestPlayer: Player = playerList[0]
        var distance: Double
        
        for i in 1...playerList.count {
            
            distance = getDistance(mainPlayer, playerList[i])
            
            if (playerList[i] != mainPlayer && distance < closestDistance){
                closestDistance = distance
                closestPlayer = playerList[i]
            }
            
        }
        return closestPlayer
    }
    
}
