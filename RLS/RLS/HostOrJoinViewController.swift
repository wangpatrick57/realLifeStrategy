//
//  HostOrJoinViewController.swift
//  
//
//  Created by Melody Lee on 8/1/18.
//

import UIKit
import FirebaseFirestore

var gameID:String = "generating"
var gameCol = "Games"
let gameIDLength:Int = 5
let db = Firestore.firestore()
let debug = true

class HostOrJoinViewController : UIViewController {
    @IBAction func HostButton(_ sender: Any) {
        //gameID = generateGameID()
        gameID = generateGameID()
        
        while(networking.checkGameIDTaken(idToCheck: gameID, hostOrJoin: "h")) {
            print("\(gameID) taken")
            gameID = generateGameID()
        }
        
        print("\(gameID) not taken")
        self.performSegue(withIdentifier: "ShowCustomizeGame", sender: self)
    }
    
    @IBAction func JoinButton(_ sender: Any) {
        print("Join Button clicked")
        self.performSegue(withIdentifier: "JoinGameIDSegue", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (debug) {
            gameCol = "TestingGames"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func generateGameID()->String {
        var gameID:String = ""
        let alphabet: [String] = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
        
        for _ in 1...gameIDLength {
            let rand:Int = Int(arc4random_uniform(26))
            gameID += alphabet[rand]
        }
        
        return gameID
    }
}
