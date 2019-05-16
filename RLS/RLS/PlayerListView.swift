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
import Firebase

var myPlayer:Player = Player()

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
    var respawnPointNum: Int = 0
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        redButton.backgroundColor = redUnselected
        blueButton.backgroundColor = blueUnselected
        nicknameLabel.text = "Hi, " + nickname + "! Choose a team below:"
        idLabel.text = "Game ID: " + gameID
        
        if (nickname == "host") {
            let docRef = db.collection("Games").document(gameID)
            
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let data = document.data()
                    if let data = data {
                        self.respawnPointNum = data["numRespawnPoints"] as! Int
                    } else {
                        print("a")
                    }
                } else {
                    print("document doesn't exist")
                }
            }
            
            print(respawnPointNum)
            
            for i in 0..<respawnPointNum {
                db.document("Games/\(gameID)/RespawnPoints/point\(i)").updateData([
                    "lat": 0,
                    "long": 0
                    ])
            }
        }
    }
    
    @IBAction func enterGamePressed(_ sender: Any) {
        if (team != "") {
            myPlayer = Player(name: nickname, team: team, coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
            
            db.document("Games/" + gameID + "/Players/" + myPlayer.getName()).updateData([
                "team": team
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
            
            self.performSegue(withIdentifier: "ShowMap", sender: self)
        }
    }
    
//    @IBOutlet weak var redPlayersScroll: UIScrollView!
//
//    @IBAction func teamSelected(_ sender: UIButton) {
//        if sender.tag == 1{
//            team = "Red"
//        }
//        if sender.tag == 2{
//            team = "Blue"
//        }
//        print(team)
//    }
}
