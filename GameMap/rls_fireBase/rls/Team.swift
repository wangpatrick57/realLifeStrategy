//
//  Team.swift
//  rls
//
//  Created by Ethan Soo on 4/21/18.
//  Copyright © 2018 Ethan Soo. All rights reserved.
//

import Foundation
class Team {
    var color:TeamColor
    var playerList: [Player]
    init(color:TeamColor) {
        self.color = color
        playerList = []
    }
    
    func addPlayer(player:Player) -> Void {
        playerList.append(player)
        update()
    }
    
    func removePlayer(id:Int) -> Void {
        playerList[id-1].id = 0
        playerList.remove(at: id-1)
        update()
    }
    
    func update() -> Void {
        for i in 1...playerList.count+1{
            playerList[i].id = i
        }
    }
}

enum TeamColor: String{
    case red = "red"
    case blue = "blue"
}
