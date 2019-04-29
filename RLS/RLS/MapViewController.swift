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

var myPlayer:Player? = nil

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
            print(location.coordinate.latitude, " and ", location.coordinate.longitude)
            self.map.showsUserLocation = false
            once = true
        }
        
        db.document("Games/" + gameId + "/Players/" + nickname).updateData([
            "lat": location.coordinate.latitude,
            "long": location.coordinate.longitude
            ])
    }
    
    override func viewDidLoad() {
        //necessary map stuff
        super.viewDidLoad()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
        //start timer
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
        //eventually make a server app that calculates vision so that the clients don't have access to all the enemies' positions
        db.collection("Games/" + gameId + "/Players").getDocuments() { (querySnapshot, error) in
            if let error = error{
                print(error)
            } else {
                for ann in self.map.annotations{
                    self.map.removeAnnotation(ann)
                }
                
                for document in querySnapshot!.documents {
                    if (self.hasVisionOf(document: document)) {
                        let data = document.data()
                        let coordinate = CLLocationCoordinate2D(latitude: data["lat"] as! Double, longitude: data["long"] as! Double)
                        let thisPlayer = Player(name: document.documentID, team: data["team"] as! String, coordinate: coordinate)
                        
                        /*if let index = self.playerList.firstIndex(of: thisPlayer) {
                            
                        } else {
                            self.playerList[self.playerList.count] = thisPlayer
                        }*/
                        
                        self.map.addAnnotation(thisPlayer)
                    }
                }
            }
        }
    }
    
    func hasVisionOf(document: DocumentSnapshot) -> Bool {
        if let data = document.data() {
            if (data["team"] as? String ?? "none" == team) {
                return true
            }
            
            let lat1 : Double
            let lon1 : Double
            let lat2 : Double = data["lat"] as? Double ?? 999
            let lon2 : Double = data["long"] as? Double ?? 999
            
            if let player = myPlayer {
                let coord = player.getCoordinate()
                lat1 = coord.latitude
                lon1 = coord.longitude
                
                if (latLongDist(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2) < player.visionDist) {
                    return true
                }
            }
        } else {
            print("data is nil")
        }
        
        return false
    }
    
    func latLongDist(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6378.137 // Radius of earth in KM
        let dLat = lat2 * Double.pi / 180 - lat1 * Double.pi / 180
        let dLon = lon2 * Double.pi / 180 - lon1 * Double.pi / 180
        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1 * Double.pi / 180) * cos(lat2 * Double.pi / 180) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        let d = R * c
        return d * 1000 // meters
    }
    
    func setData() {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}


