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
        print("Host Button clicked")
        //gameID = generateGameID()
        gameID = generateGameID()
        
        while(networking.checkGameIDTaken(idToCheck: gameID)) {
            print("\(gameID) taken")
            gameID = generateGameID()
        }
        
        print("\(gameID) not taken")
        self.performSegue(withIdentifier: "HostGameIDSegue", sender: self)
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
        
        //start step function timer
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(step), userInfo: nil, repeats: true)
    }
    
    @objc func step() {
        //send heartbeat
        networking.sendHeartbeat()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func generateGameID()->String {
        var gameID:String = ""
        let alphabet: [String] = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
        
        for i in 1...gameIDLength {
            let rand:Int = Int(arc4random_uniform(36))
            var add:String
            
            if (rand < 10) {
                add = String(rand)
            } else {
                add = alphabet[rand - 10]
            }
            
            gameID += add
        }
        
        return gameID
    }
    
    func checkIDTakenFirebase() {
        gameID = generateGameID()
        let docRef:DocumentReference = db.document("\(gameCol)/\(gameID)")
        
        docRef.getDocument { (document, error) in
            if let document = document {
                if document.exists {
                    print(gameID + " taken")
                    self.checkIDTakenFirebase()
                } else {
                    db.document("\(gameCol)/\(gameID)").setData([
                        "test": "test"
                    ]) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written!")
                        }
                    }
                    
                    print(gameID + " not taken")
                    self.performSegue(withIdentifier: "HostGameIDSegue", sender: self)
                }
            }
        }
    }
}
