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
let deathTime = 5.0
let tetherDist = 20.0
var respawnTime = 15.0 //seconds
let respawnDist = 20.0 //meters
let cpDist = 50.0 //meters
let wardVisionDist = 30.0 //meters
let font : String = "San Francisco"

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

