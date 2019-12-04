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
    
    //param: player A, player B
    //return distance between both players in meters
    static func getMeterDistance(_ playerX: Player, _ playerY: Player) -> Double{
        let lat1 = playerX.getCoordinate().latitude
        let lat2 = playerY.getCoordinate().latitude
        let lon1 = playerX.getCoordinate().longitude
        let lon2 = playerY.getCoordinate().longitude
        
        let R = 6378.137; // Radius of earth in KM
        let dLat = lat2 * Double.pi / 180 - lat1 * Double.pi / 180;
        let dLon = lon2 * Double.pi / 180 - lon1 * Double.pi / 180;
        let a = sin(dLat/2) * sin(dLat/2) +
            cos(lat1 * Double.pi / 180) * cos(lat2 * Double.pi / 180) *
            sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a));
        let d = R * c;
        return d * 1000; // meters
        
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
    
    //param: main player, list of all players in game, range in meters
    //return array of players within range
    static func getPlayersInRange(mainPlayer: Player, playerList: [Player], range: Double)->[Player]{
        var newList: [Player] = [Player]()
        for i in 0...playerList.count {
            if (getMeterDistance(mainPlayer, playerList[i]) <= range){
                newList.append(playerList[i])
            }
        }
        return newList
    }
}
