//
//  NicknameLabel.swift
//  GameMap
//
//  Created by Melody Lee on 4/22/18.
//  Copyright © 2018 Hackathon Event. All rights reserved.
//

import UIKit

class NicknameLabel: UIViewController {
    
    var team = String()
    
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var label: UILabel!
    
    var nickname = String()
    var id = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        label.text = nickname
        idLabel.text = id
    }
    
    @IBAction func teamSelected(_ sender: UIButton) {
        if sender.tag == 1{
            team = "Red"
        }
        if sender.tag == 2{
            team = "Blue"
        }
        print(team)
    }
    //MARK: Actions
    
}
