//
//  NicknameTFView.swift
//  GameMap
//
//  Created by Melody Lee on 4/22/18.
//  Copyright © 2018 Hackathon Event. All rights reserved.
//

import Foundation
import UIKit
import FirebaseFirestore

var nickname:String = ""

class NicknameTFView: UIViewController {
    @IBOutlet weak var gameIDLabel: UILabel!
    @IBOutlet weak var nicknameTF: UITextField!
    var id = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gameIDLabel.text = "Game ID: " + gameID
        
        db.document("\(gameCol)/\(gameID)").setData([
            "respawnPointNum": 0
            ])
    }
    
    @IBAction func JoinButton(_ sender: Any) {
        let enteredName = nicknameTF.text ?? ""
        
        if (enteredName != "") {
            if (networking.checkNameTaken(nameToCheck: enteredName)) {
                print("\(enteredName) taken")
            } else {
                nickname = enteredName
                self.performSegue(withIdentifier: "PlayerListSegue", sender: self)
            }
        }
    }
    
    func checkNameTaken() {
        nickname = nicknameTF.text ?? ""
        
        let docRef:DocumentReference = db.document("\(gameCol)/\(gameID)/Players/\(nickname)")
        
        docRef.getDocument { (document, error) in
            if let document = document {
                if document.exists {
                    print(nickname + " taken")
                } else {
                    db.document("\(gameCol)/\(gameID)/Players/\(nickname)").setData([
                        "lat": 0,
                        "long": 0,
                        "dead": false
                    ]) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written!")
                        }
                    }
                    
                    print(nickname + " not taken")
                    self.performSegue(withIdentifier: "PlayerListSegue", sender: self)
                }
            }
        }
    }
    
    func isSpectator() -> Bool{
        if nicknameTF.text == ".SPECTATOR"{
            self.performSegue(withIdentifier: "spectatorSegue", sender: self)
            return true
        }
        return false
    }
}
