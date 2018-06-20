//
//  File.swift
//  rls
//
//  Created by Ethan Soo on 4/22/18.
//  Copyright © 2018 Ethan Soo. All rights reserved.
//

import Foundation
import Firebase

class LocalPlayer {
    var playId:String
    var team:String
    var name:String
    var ref:DatabaseReference
    var initialized:Bool
    var knownPlayers:[Player]
    
    init(name:String, team:String) {
        //Create dummy if missing
        self.playId = "filler"
        self.name = "exDee"
        self.team = "red"
        ref = Database.database().reference()
        initialized = false
        knownPlayers = []
        self.push()
        self.team = "blue"
        self.push()
        
        self.name = name
        self.team = team
        
        
        ref.child("Players").observeSingleEvent(of: .value) { (snapshot) in
            let currentPlayers = snapshot.value as! [String: AnyObject]
            //print(currentPlayers)
            var createdPlayer:Bool = false
            var i:Int = 1
            while createdPlayer == false{
                if currentPlayers["\(i)"] == nil{
                    self.playId = "\(i)"
                    self.push()
                    self.initialized = true
                    createdPlayer = true
                }
                i=i+1
            }
        }
        
    }
    
    func push() -> Void {
        ref.child("Players").child(playId).child("name").setValue(self.name)
        ref.child("Players").child(playId).child("team").setValue(self.team)
        ref.child("\(team)").child(playId).child("longitude").setValue(0)
        ref.child("\(team)").child(playId).child("latitude").setValue(0)
    }
    
    func setLocation(longitude:Double, latitude:Double) -> Void {
        if initialized {
            ref.child("\(team)").child(playId).child("longitude").setValue(longitude)
            ref.child("\(team)").child(playId).child("latitude").setValue(latitude)
        }
    }
    
    func remove() -> Void {
        ref.child("Players").child(playId).setValue(nil)
        ref.child("\(team)").child(playId).setValue(nil)
    }
    
    func addKnown(player:Player) -> Void {
        knownPlayers.append(player)
    }
}
