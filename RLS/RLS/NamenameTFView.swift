//
//  NicknameTFView.swift
//  GameMap
//
//  Created by Melody Lee on 4/22/18.
//  Copyright © 2018 Hackathon Event. All rights reserved.
//

import UIKit

class NicknameTFView: UIViewController {
    
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var nickNameTF: UITextField!
    
    var id = "Game ID: X"
    
    @IBAction func enterPressed(_ sender: EnterButton) {
        performSegue(withIdentifier: "segue4", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let senderButton = sender as? EnterButton
        
        if senderButton?.isTouchInside == true {
            let nicknameLController = segue.destination as! NicknameLabel
            nicknameLController.nickname = "Hi, " + nickNameTF.text! + "!"
            nicknameLController.id = self.id
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        idLabel.text = id
    }
}
