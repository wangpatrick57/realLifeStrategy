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
    var annotation: Player = Player(name: "Bob", team: "Red", id: 1, coordinates: CLLocationCoordinate2DMake(0,0))
    var myLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude:0,longitude: 0)
    var x: Float = 0
    var y: Float = 0
    var timer: Timer!
    var colRef: CollectionReference!
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        if (!once){
            let span: MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
            myLocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
            let region:MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
            map.setRegion(region, animated: true)
            //print(location.coordinate.latitude, " and ", location.coordinate.longitude)
            self.map.showsUserLocation = true
            annotation = Player(name: "Bob",team: "Red",id: 1,coordinates: myLocation)
            map.addAnnotation(annotation)
            once = true
        }
        db.document("Games/" + gameId + "/Players/" + nickname)
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(getData), userInfo: nil, repeats: true)
        colRef = Firestore.firestore().collection("Games").document("gameOne").collection("Red Players")
        print("col Ref initialized")
        /*[UIView animateWithDuration:0.3f
         animations:^{
         myAnnotation.coordinate = newCoordinate;
         }]*/
    }
    
    @objc func getData() {
        colRef.getDocuments() { (querySnapshot, error) in
            if let error = error{
                print(error)
            } else {
                for ann in self.map.annotations{
                    self.map.removeAnnotation(ann)
                }
                for playerDoc in querySnapshot!.documents {
                    let myData = playerDoc.data()
                    self.myLocation = CLLocationCoordinate2D(latitude: Double(myData["Latitude"] as? Float ?? 20), longitude: Double(myData["Longitude"] as? Float ?? 20))
                    self.annotation = Player(name: "James", team: "Red", id: 1, coordinates: self.myLocation)
                    print(self.myLocation.latitude, " and ", self.myLocation.longitude)
                    self.map.addAnnotation(self.annotation)
                }
                //print("Query exists")
            }
        }
        //print (x, " and ", y)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}


