//
//  Game.swift
//  rls
//
//  Created by Ethan Soo on 4/22/18.
//  Copyright © 2018 Ethan Soo. All rights reserved.
//

import Foundation
import Firebase

class GameHost {
    var redTeam:Team
    var blueTeam:Team
    var boundPoints:[Double]
    var ref:DatabaseReference!
    var gameID:Int

    init(longOne:Double, latOne:Double, longTwo:Double, latTwo:Double) {
        boundPoints = []
        boundPoints.append(longOne)
        boundPoints.append(latOne)
        boundPoints.append(longTwo)
        boundPoints.append(latTwo)
        redTeam = Team(color: TeamColor.red)
        blueTeam = Team(color: TeamColor.blue)
        gameID = -1
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
    
    func clear() -> Void {
        //clear the data from firebase
    }
}
