//
//  ManageControlPointView.swift
//  RLS
//
//  Created by Melody Lee on 8/18/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//

import Foundation
import UIKit

class ManageControlPointView : UIViewController {
    @IBOutlet weak var latTF: UITextField!
    @IBOutlet weak var longTF: UITextField!
    @IBAction func EnterButton(_ sender: Any) {
        print("Enter Button clicked")
        let latitude = Double(latTF.text ?? "") ?? 0
        let longitude = Double(longTF.text ?? "") ?? 0
        
        networking.sendCPLoc(lat: latitude, long: longitude)
    }
    
}
