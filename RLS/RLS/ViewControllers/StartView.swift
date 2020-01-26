//
//  ViewController.swift
//  RLS
//
//  Created by Melody Lee on 7/7/18.
//  Copyright © 2018 Melody Lee. All rights reserved.
//

import UIKit
import MapKit

let networking = Networking()
var stepTimer: Timer!
let deathTime = 5.0
let tetherDist = 20.0
var respawnTime = 15.0 //seconds
let respawnDist = 20.0 //meters
let cpDist = 50.0 //meters
let wardVisionDist = 30.0 //meters
let shadowInterval = 1.0 // seconds
let enableShadows = false
let packetLossChance: Float = 0
let disconnectTimeout: Int = 10
let font : String = "San Francisco"
var inGame = false
var inBackground = false
var recRP = false
var borderPoints: [BorderPoint] = []
var respawnPoints: [RespawnPoint] = []
var createdBorderPoints: [BorderPoint] = []
var createdRespawnPoints: [RespawnPoint] = []
var gameID:String = "generating"
var nickname:String = ""
var gameCol = "Games"
let gameIDLength:Int = 5
let debug = false
var uuid: String = ""

class StartView: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        print("setting uuid")
        uuid = UIDevice.current.identifierForVendor!.uuidString
        print("uuid set successfully")
        
        //setup client
        print("networking in start")
        networking.setupNetworkComms()
    }
    
    func printStuff(_ content: String) {
        print("hi")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

