//
//  HostOrJoinViewController.swift
//  
//
//  Created by Melody Lee on 8/1/18.
//

import UIKit
import Firebase
import FirebaseFirestore

var gameId:String = "generating"
let gameIdLength:Int = 5
let db = Firestore.firestore()
let debug = true

class HostOrJoinViewController : UIViewController {
    @IBAction func HostButton(_ sender: Any) {
        print("Host Button clicked")
        checkIdTaken()
    }
    
    @IBAction func JoinButton(_ sender: Any) {
        print("Join Button clicked")
        self.performSegue(withIdentifier: "JoinGameIDSegue", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func checkIdTaken() {
        gameId = generateGameId()
        let docRef:DocumentReference = db.document("Games/" + gameId)
        
        docRef.getDocument { (document, error) in
            if let document = document {
                if document.exists {
                    print(gameId + " taken")
                    self.checkIdTaken()
                } else {
                    db.document("Games/" + gameId).setData([
                        "test": "test"
                    ]) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written!")
                        }
                    }
                    
                    print(gameId + " not taken")
                    self.performSegue(withIdentifier: "HostGameIDSegue", sender: self)
                }
            }
        }
    }
    
    func generateGameId()->String {
        var gameId: String = ""
        let alphabet: [String] = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
        
        for i in 1...gameIdLength {
            let rand:Int = Int(arc4random_uniform(36))
            var add:String
            
            if (rand < 10) {
                add = String(rand)
            } else {
                add = alphabet[rand - 10]
            }
            
            gameId += add
        }
        
        return gameId
    }
}
