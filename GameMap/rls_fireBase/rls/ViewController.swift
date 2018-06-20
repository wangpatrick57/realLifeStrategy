//
//  ViewController.swift
//  rls
//
//  Created by Ethan Soo on 4/21/18.
//  Copyright © 2018 Ethan Soo. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ViewController: UIViewController {

    @IBOutlet weak var playerName: UITextField!
    @IBOutlet weak var label: UILabel!
    
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set firebase reference
        ref = Database.database().reference()

        //retrieve the data and listen for changes
        databaseHandle = ref?.child("Game1").child("Teams").child("Blue").child("Player1").observe(DataEventType.childChanged, with: { (name) in
            //try to convert data into a string
            let temp = name.value as? String
            if let actualName = temp {
                //set data to label
                self.label.text = actualName
            }
            //code to execute when child is changed
            
        })
 
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func submitName(_ sender: Any) {
        ref?.child("Game1").child("Teams").child("Blue").child("Player1").child("Name").setValue(playerName.text)
        
        LocalPlayer(name: "Jimmy",team: "blue")
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

