//
//  GameIDTF.swift
//  GameMap
//
//  Created by Melody Lee on 4/22/18.
//  Copyright © 2018 Hackathon Event. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class GameIDTF: UIViewController {
    @IBOutlet var idTF: UITextField!
    
    @IBAction func EnterButton(_ sender: Any) {
        print("Enter Button clicked")
        checkGameExists()
    }
    
    func checkGameExists() {
        gameID = idTF.text!
        let docRef:DocumentReference = db.document("Games/" + gameID)
        
        docRef.getDocument { (document, error) in
            if let document = document {
                if document.exists {
                    print(gameID + " exists")
                    self.performSegue(withIdentifier: "JoinEnterNicknameSegue", sender: self)
                } else {
                    print(gameID + " doesn't exists")
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            var DestViewController : NicknameTFView = segue.destination as! NicknameTFView
            DestViewController.id = idTF.text!
    }
}
