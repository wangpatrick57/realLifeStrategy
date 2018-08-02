//
//  GameIDTF.swift
//  GameMap
//
//  Created by Melody Lee on 4/22/18.
//  Copyright © 2018 Hackathon Event. All rights reserved.
//

import Foundation
import UIKit

class GameIDTF: UIViewController {
    @IBOutlet var idTF: UITextField!
    @IBAction func EnterButton(_ sender: Any) {
        print("Enter Button clicked")
        self.performSegue(withIdentifier: "JoinEnterNicknameSegue", sender: self)
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
