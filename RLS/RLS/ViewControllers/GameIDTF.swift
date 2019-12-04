//
//  GameIDTF.swift
//  GameMap
//
//  Created by Melody Lee on 4/22/18.
//  Copyright © 2018 Hackathon Event. All rights reserved.
//

import Foundation
import UIKit

class GameIDTF: UIViewController {
    @IBOutlet var idTF: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func enterPressed(_ sender: Any) {
        gameID = idTF.text ?? ""
        
        if (networking.checkGameIDTaken(idToCheck: gameID, hostOrJoin: "j")) {
            self.performSegue(withIdentifier: "JoinEnterNicknameSegue", sender: self)
        } else {
            print("\(gameID) doesn't exists")
        }
    }
    
    @IBAction func returnPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "ShowHostOrJoin", sender: nil)
    }
}
