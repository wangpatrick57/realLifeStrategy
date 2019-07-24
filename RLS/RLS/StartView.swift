//
//  ViewController.swift
//  RLS
//
//  Created by Melody Lee on 7/7/18.
//  Copyright © 2018 Melody Lee. All rights reserved.
//

import UIKit

let networking = Networking()
var timer: Timer!

class StartView: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup client
        print("networking in start")
        networking.setupNetworkComms()
        
        //start step function timer
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(step), userInfo: nil, repeats: true)
    }
    
    @objc func step() {
        //send heartbeat
        networking.readAllData() //read all data to check if bt was received to know whether or not to send hrt
        networking.sendHeartbeat()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

