//
//  ViewController.swift
//  RLS
//
//  Created by Melody Lee on 7/7/18.
//  Copyright © 2018 Melody Lee. All rights reserved.
//

import UIKit

let networking = Networking()
var stepTimer: Timer!
let deathTime = 5.0
let tetherDist = 20.0
var respawnTime = 15.0 //seconds
let respawnDist = 20.0 //meters
let cpDist = 50.0 //meters
let wardVisionDist = 30.0 //meters
let packetLossChance: Float = 0.0
let font : String = "San Francisco"
var inGame = false
var recBrd = false
var recRP = false

class StartView: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup client
        print("networking in start")
        networking.setupNetworkComms()
        
        //start serverStep timer
        _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(serverStep), userInfo: nil, repeats: true)
    }
    
    @objc func serverStep() {
        networking.readAllData() //read all data to check if bt was received to know whether or not to send hrt
        networking.sendHeartbeat()
        networking.broadcastOneTimers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

