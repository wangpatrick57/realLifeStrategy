//
//  CustomizeGameView.swift
//  RLS
//
//  Created by Patrick Wang on 10/7/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//

import Foundation
import UIKit

class CustomizeGameView: UIViewController {
    @IBOutlet weak var gameIDLabel: UILabel!
    
    override func viewDidLoad() {
        gameIDLabel.text = "Game ID: \(gameID)"
    }
    
    @IBAction func editBorderPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "ShowBorderEditor", sender: nil)
    }
    
    @IBAction func editRespawnPointsPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "ShowRespawnPointEditor", sender: nil)
    }
    
    @IBAction func donePressed(_ sender: Any) {
        for i in 0..<createdBorderPoints.count {
            networking.setSendBP(value: true, index: i)
        }
        
        for i in 0..<createdRespawnPoints.count {
            networking.setSendRP(value: true, index: i)
        }
        
        self.performSegue(withIdentifier: "ShowNickname", sender: nil)
    }
}
