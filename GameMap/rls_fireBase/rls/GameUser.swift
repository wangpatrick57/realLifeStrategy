//
//  GameUser.swift
//  rls
//
//  Created by Ethan Soo on 4/22/18.
//  Copyright © 2018 Ethan Soo. All rights reserved.
//

import Foundation
import Firebase

class GameUser {
    var ref:DatabaseReference!
    var gameID:Int
    var team:String
    var playerID:Int
    var playerName:String
    
    init(gID:Int) {

        gameID = -1
        team = "red"
        playerName = ""
        playerID = 0
        //Firebase stuff
        ref = Database.database().reference()
        ref.observeSingleEvent(of: .value) { (snapshot) in
            let allGames = snapshot.value as! [String: AnyObject]
            var createGame:Bool = false
            var i:Int = 1
            while createGame == false{
                if allGames["\(i)"] == nil{
                    //create game(i)
                    self.gameID = i
                    createGame = true
                }
                i=i+1
            }
        }
    }
    func setName(name:String) -> Void {
        self.playerName = name
        ref.child("\(gameID)").child(team).child("\(playerID)").child("name").setValue(playerName)
    }
    func setTeam(teamColor:TeamColor) -> Void {
        self.team = teamColor.rawValue
    }
    func getPlayerName(playerID:Int) -> String {
        var pName:String = "Person does not exist"
        ref.child("\(gameID)").child(team).child("\(playerID)").observeSingleEvent(of: .value) { (snapshot) in
            let dataDict = snapshot.value as! [String:AnyObject]
            let name = dataDict["name"] as! String
            pName = name
        }
        return pName
    }
    
    func getPlayerLong(playerID:Int) -> Double {
        var pLong:Double = -777
        ref.child("\(gameID)").child(team).child("\(playerID)").observeSingleEvent(of: .value) { (snapshot) in
            let dataDict = snapshot.value as! [String:AnyObject]
            let long = dataDict["long"] as! Double
            pLong = long
        }
        return pLong
    }
    func getPlayerLat(playerID:Int) -> Double {
        var pLat:Double = -777
        ref.child("\(gameID)").child(team).child("\(playerID)").observeSingleEvent(of: .value) { (snapshot) in
            let dataDict = snapshot.value as! [String:AnyObject]
            let lat = dataDict["lat"] as! Double
            pLat = lat
        }
        return pLat
    }

    func clear() -> Void {
        //clear the data from firebase
    }
}
