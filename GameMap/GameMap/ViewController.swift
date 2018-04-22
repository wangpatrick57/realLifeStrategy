//
//  ViewController.swift
//  GameMap
//
//  Created by Hackathon Event on 4/21/18.
//  Copyright © 2018 Hackathon Event. All rights reserved.
//
//
//www.raywenderlich.com/160517/mapkit-tutorial-getting-started

import UIKit
import MapKit

class ViewController: UIViewController {
    @IBOutlet weak var mapImageView: UIImageView!
    
     override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
    
    // MARK: Properties
    //@IBOutlet weak var mapView: MKMapView!
    
    //MARK: Actions
    @IBAction func touchExit(_ sender: UITapGestureRecognizer) {
        print("touched")
    }
    @IBAction func gameIDTF(_ textField: UITextField) {
    }
}


