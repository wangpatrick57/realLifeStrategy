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
let debug = false

class HostOrJoinViewController : UIViewController {
    @IBAction func HostButton(_ sender: Any) {
        print("Host Button clicked")
        checkIDTaken()
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
    
    func checkIDTaken() {
        gameID = generateGameID()
        let docRef:DocumentReference = db.document("\(gameCol)/\(gameID)")
        
        docRef.getDocument { (document, error) in
            if let document = document {
                if document.exists {
                    print(gameID + " taken")
                    self.checkIDTaken()
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
}
