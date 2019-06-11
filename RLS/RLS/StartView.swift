//
//  ViewController.swift
//  RLS
//
//  Created by Melody Lee on 7/7/18.
//  Copyright © 2018 Melody Lee. All rights reserved.
//

import UIKit

let networking = Networking()

class StartView: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup client
        print("networking in start")
        networking.setupNetworkComms()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

