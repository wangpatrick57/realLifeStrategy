//
//  HostOrJoinViewController.swift
//  
//
//  Created by Melody Lee on 8/1/18.
//

import UIKit

class HostOrJoinViewController : UIViewController{
    @IBAction func HostButton(_ sender: Any) {
        print("Host Button clicked")
        self.performSegue(withIdentifier: "HostGameIDSegue", sender: self)
    }
    
    @IBAction func JoinButton(_ sender: Any) {
        print("Join Button clicked")
        self.performSegue(withIdentifier: "JoinGameIDSegue", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
