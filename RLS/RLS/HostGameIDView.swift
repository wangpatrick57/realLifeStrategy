//
//  HostGameIDView.swift
//  
//
//  Created by Melody Lee on 8/1/18.
//

import Foundation
import UIKit
import FirebaseFirestore

class HostGameIDView : UIViewController {
    @IBOutlet weak var HostGameID: UILabel!
    @IBAction func NextButton(_ sender: Any) {
        print("Next Button clicked")
        self.performSegue(withIdentifier: "EnterNicknameSegue", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        HostGameID.text = "Game ID: " + gameID
        
        //start step function timer
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(step), userInfo: nil, repeats: true)
    }
    
    @objc func step() {
        //send heartbeat
        networking.readAllData()
        networking.sendHeartbeat()
    }
    
    override func didReceiveMemoryWarning() {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //var DestViewController : NicknameTFView = segue.destination as! NicknameTFView
    }
}
