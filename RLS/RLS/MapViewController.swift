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
    var playerDict: [String: Player] = [:]
    var myTeamDict: [String: Player] = [:]
    var otherTeamDict: [String: Player] = [:]
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
            let span: MKCoordinateSpan = MKCoordinateSpan.init(latitudeDelta: 0.01, longitudeDelta: 0.01)
            myLocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
            let region:MKCoordinateRegion = MKCoordinateRegion.init(center: myLocation, span: span)
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
                //this loop is to check for new players and update existing ones
                //don't run this every frame; instead, run this on a button called update players
                for document in querySnapshot!.documents {
                    let data = document.data()
                    let thisCoordinate = CLLocationCoordinate2D(latitude: data["lat"] as! Double, longitude: data["long"] as! Double)
                    let thisTeam = data["team"] as? String ?? "none"
                    let thisName = document.documentID
                    var inList = false
                    
                    for key in self.playerDict.keys {
                        if (key == thisName) {
                            inList = true
                            break
                        }
                    }
                    
                    if (inList) {
                        self.playerDict[thisName]?.setCoordinate(coordinate: thisCoordinate)
                        self.playerDict[thisName]?.setTeam(team: thisTeam)
                    } else {
                        let playerToAdd = Player(name: thisName, team: data["team"] as? String ?? "none", coordinate: thisCoordinate)
                        self.playerDict[thisName] = playerToAdd
                    }
                    
                    if (thisTeam == team) {
                        self.myTeamDict[thisName] = self.playerDict[thisName]
                        
                        if self.otherTeamDict.index(forKey: thisName) != nil {
                            self.otherTeamDict.removeValue(forKey: thisName)
                        }
                    } else if (thisTeam != "none"){
                        self.otherTeamDict[thisName] = self.playerDict[thisName]
                        
                        if self.myTeamDict.index(forKey: thisName) != nil {
                            self.myTeamDict.removeValue(forKey: thisName)
                        }
                    }
                }
            }
        }
        
        //remove all annotations
        for ann in self.map.annotations{
            self.map.removeAnnotation(ann)
        }
        
        //check for vision and add the annotations
        for key in self.myTeamDict.keys {
            if let thisPlayer = self.myTeamDict[key] {
                self.map.addAnnotation(thisPlayer)
            }
        }
        
        for key in self.otherTeamDict.keys {
            if let playerToCheck = self.otherTeamDict[key] {
                if (self.hasVisionOf(playerToCheck: playerToCheck)) {
                    self.map.addAnnotation(playerToCheck)
                }
            }
        }
    }
    
    func hasVisionOf(playerToCheck: Player) -> Bool {
        if (playerToCheck.getTeam() == team) {
            return true
        }
        
        var lat1 : Double
        var lon1 : Double
        let coordToCheck = playerToCheck.getCoordinate()
        let lat2 : Double = coordToCheck.latitude
        let lon2 : Double = coordToCheck.longitude
        
        for key in myTeamDict.keys {
            if let thisPlayer = myTeamDict[key] {
                let coord = thisPlayer.getCoordinate()
                lat1 = coord.latitude
                lon1 = coord.longitude
                
                if (latLongDist(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2) < thisPlayer.visionDist) {
                    return true
                }
            }
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


