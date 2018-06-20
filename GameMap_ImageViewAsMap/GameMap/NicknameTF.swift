//
//  NicknameTF.swift
//  GameMap
//
//  Created by Melody Lee on 4/22/18.
//  Copyright © 2018 Hackathon Event. All rights reserved.
//

import UIKit

class NicknameTF: UIViewController {
    
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var nickNameTF: UITextField!
    
    var id = "Game ID: 12345"
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        var senderButton = sender as? EnterButton
        
        if senderButton?.isTouchInside == true {
            print("true")
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
    
    //MARK: Actions

    @IBAction func enterPressed(_ sender: EnterButton) {
        if nickNameTF.text != "" {
            performSegue(withIdentifier: "segue", sender: self)
        }
    }
}
