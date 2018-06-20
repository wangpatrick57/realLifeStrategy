//
//  GameIDTF.swift
//  GameMap
//
//  Created by Melody Lee on 4/22/18.
//  Copyright © 2018 Hackathon Event. All rights reserved.
//

import UIKit

class GameIDTF: UIViewController {
        
    @IBOutlet weak var idTF: UITextField!
    
    @IBAction func enter(_ sender: EnterButton) {
        if idTF.text != ""{
            performSegue(withIdentifier: "segue1", sender: self)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            
        let senderButton = sender as? EnterButton
            
        if senderButton?.isTouchInside == true {
            let idLController = segue.destination as! NicknameTF
            idLController.id = "GameID: " + idTF.text!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

}
