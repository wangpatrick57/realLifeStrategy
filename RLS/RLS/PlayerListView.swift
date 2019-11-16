//
//  PlayerListView.swift
//  RLS
//
//  Created by Melody Lee on 8/1/18.
//  Copyright © 2018 Melody Lee. All rights reserved.
//

import Foundation
import MapKit
import UIKit

var myPlayer:Player = Player(name: "")

class PlayerListView : UIViewController{
    
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var redButton: UIButton!
    @IBOutlet weak var blueButton: UIButton!
    
    var redUnselected: UIColor = UIColor(red: 247.0/255.0, green: 181.0/255.0, blue: 167.0/255.0, alpha: 1.0)
    var redSelected: UIColor = UIColor(red: 246.0/255.0, green: 91.0/255.0, blue: 73.0/255.0, alpha: 1.0)
    var blueUnselected: UIColor = UIColor(red: 167.0/255.0, green: 177.0/255.0, blue: 247.0/255.0, alpha: 1.0)
    var blueSelected: UIColor = UIColor(red: 73.0/255.0, green: 94.0/255.0, blue: 246.0/255.0, alpha: 1.0)
    var team: String = ""
    var respawnPointNum: Int = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        redButton.backgroundColor = redUnselected
        blueButton.backgroundColor = blueUnselected
        nicknameLabel.text = "Hi, " + nickname + "! Choose a team below:"
        idLabel.text = "Game ID: " + gameID
    }
    
    @IBAction func redSelected(_ sender: Any) {
        team = "red"
        redButton.backgroundColor = redSelected
        blueButton.backgroundColor = blueUnselected
    }
    
    @IBAction func blueSelected(_ sender: Any) {
        team = "blue"
        redButton.backgroundColor = redUnselected
        blueButton.backgroundColor = blueSelected
    }
    
    @IBAction func enterGamePressed(_ sender: Any) {
        if (team != "") {
            myPlayer = Player(name: nickname)
            myPlayer.setTeam(team: team)
            networking.setSendTeam(st: true)
            self.performSegue(withIdentifier: "ShowMap", sender: self)
        }
    }
}
