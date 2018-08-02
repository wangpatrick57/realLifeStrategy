//
//  NicknameTFView.swift
//  GameMap
//
//  Created by Melody Lee on 4/22/18.
//  Copyright © 2018 Hackathon Event. All rights reserved.
//

import Foundation
import UIKit

class NicknameTFView: UIViewController {
    
    @IBOutlet weak var gameID: UILabel!
    @IBOutlet weak var NickNameTF: UITextField!
    @IBAction func JoinButton(_ sender: Any) {
        print("Join Button clicked")
        self.performSegue(withIdentifier: "PlayerListSegue", sender: self)
    }
    
    var id = String()
    override func viewDidLoad() {
        super.viewDidLoad()
        gameID.text = "Game ID: " + id
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var DestViewController : PlayerListView = segue.destination as! PlayerListView
        
        DestViewController.nickname = NickNameTF.text!
        DestViewController.id = self.id
    }
    
}
