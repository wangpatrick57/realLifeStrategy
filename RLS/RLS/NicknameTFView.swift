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

class NicknameTFView: UIViewController {
    @IBOutlet weak var gameIDLabel: UILabel!
    @IBOutlet weak var nicknameTF: UITextField!
    var id = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gameIDLabel.text = "Game ID: " + gameID
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
    
    func isSpectator() -> Bool{
        if nicknameTF.text == ".SPECTATOR"{
            self.performSegue(withIdentifier: "spectatorSegue", sender: self)
            return true
        }
        return false
    }
}
