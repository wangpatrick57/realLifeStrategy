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
    @IBAction func editBorderPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "ShowBorderEditor", sender: nil)
    }
    
    @IBAction func editRespawnPointsPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "ShowRespawnPointEditor", sender: nil)
    }
}
