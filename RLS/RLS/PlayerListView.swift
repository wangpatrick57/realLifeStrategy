//
//  PlayerListView.swift
//  RLS
//
//  Created by Melody Lee on 8/1/18.
//  Copyright © 2018 Melody Lee. All rights reserved.
//

import Foundation
import UIKit

class PlayerListView : UIViewController{
    
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    
    var team = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        nicknameLabel.text = "Hi, " + nickname + "! Choose a team below:"
        idLabel.text = gameId
    }
    
    @IBOutlet weak var redPlayersScroll: UIScrollView!
    
//    @IBAction func teamSelected(_ sender: UIButton) {
//        if sender.tag == 1{
//            team = "Red"
//        }
//        if sender.tag == 2{
//            team = "Blue"
//        }
//        print(team)
//    }
}
