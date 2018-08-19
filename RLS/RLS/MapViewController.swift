//
//  ViewController.swift
//  Test
//
//  Created by Ethan Soo on 6/19/18.
//  Copyright © 2018 Ethan Soo. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Firebase

class MapViewController: UIViewController, CLLocationManagerDelegate {
    
    //map
    
    @IBOutlet weak var map: MKMapView!
    
    let manager = CLLocationManager()
    var playerList: [Player] = []
    var once = false
    var annotation: Player = Player(name: "Bob", team: "Red", coordinate: CLLocationCoordinate2DMake(0,0))
    var myLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude:0,longitude: 0)
    var x: Float = 0
    var y: Float = 0
    var timer: Timer!
    var colRef: CollectionReference!
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        print("locman")
        
        if (!once){
            let span: MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
            myLocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
            let region:MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
            map.setRegion(region, animated: true)
            //print(location.coordinate.latitude, " and ", location.coordinate.longitude)
            self.map.showsUserLocation = true
            once = true
        }
        
        db.document("Games/" + gameId + "/Players/" + nickname).updateData([
            "lat": location.coordinate.latitude,
            "long": location.coordinate.longitude
            ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(handleData), userInfo: nil, repeats: true)
        print("col Ref initialized")
        /*[UIView animateWithDuration:0.3f
         animations:^{
         myAnnotation.coordinate = newCoordinate;
         }]*/
    }
    
    @objc func handleData() {
        getData()
        //sendData()
    }
    
   func getData() {
        db.collection("Games/" + gameId + "/Players").whereField("team", isEqualTo: team).getDocuments() { (querySnapshot, error) in
            if let error = error{
                print(error)
            } else {
                for ann in self.map.annotations{
                    self.map.removeAnnotation(ann)
                }
                for document in querySnapshot!.documents {
                    if (document.documentID != nickname) {
                        let data = document.data()
                        let coordinate = CLLocationCoordinate2D(latitude: Double(data["lat"] as? Float ?? 20), longitude: Double(data["long"] as? Float ?? 20))
                        let annotation = Player(name: document.documentID, team: data["team"] as! String, coordinate: coordinate)
                        self.map.addAnnotation(annotation)
                    }
                }
            }
        }
    }
    
    func setData() {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}


