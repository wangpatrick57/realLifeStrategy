//
//  HostGameIDView.swift
//  
//
//  Created by Melody Lee on 8/1/18.
//

import Foundation
import UIKit

class HostGameIDView : UIViewController{
    @IBOutlet weak var HostGameID: UILabel!
    @IBAction func NextButton(_ sender: Any) {
        print("Next Button clicked")
        self.performSegue(withIdentifier: "EnterNicknameSegue", sender: self)
    }
    
    var id = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        HostGameID.text = "Game ID: -1"
        id = "-1"
    }
    
    override func didReceiveMemoryWarning() {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var DestViewController : NicknameTFView = segue.destination as! NicknameTFView
        
        DestViewController.id = id
    }
}
