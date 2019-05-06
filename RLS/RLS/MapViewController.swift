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
    var playerDict: [String: Player] = [:] //dictionary of all players
    var myTeamDict: [String: Player] = [:] //dictionary of players on "my" team
    var otherTeamDict: [String: Player] = [:] //dictionary of players on the "other" team
    var once = false
    var myLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude:0,longitude: 0)
    var x: Float = 0
    var y: Float = 0
    var timer: Timer!
    var colRef: CollectionReference!
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0] //the latest location
        print("locman")
        
        if (!once){
            //i'm not sure how this works someone pls comment - patrick
            let span: MKCoordinateSpan = MKCoordinateSpan.init(latitudeDelta: 0.01, longitudeDelta: 0.01)
            myLocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
            let region:MKCoordinateRegion = MKCoordinateRegion.init(center: myLocation, span: span)
            map.setRegion(region, animated: true)
            print(location.coordinate.latitude, " and ", location.coordinate.longitude)
            self.map.showsUserLocation = false
            once = true
        }
        
        //write data
        //set coordinates
        myPlayer.setCoordinate(coordinate: location.coordinate)
        
        db.document("Games/" + gameId + "/Players/" + myPlayer.getName()).updateData([
            "lat": myPlayer.getCoordinate().latitude,
            "long": myPlayer.getCoordinate().longitude
            ])
    }
    
    @IBAction func dropWard(_ sender: Any) {
        myPlayer.addWard()
        let coordinate = myPlayer.getCoordinate()
        
        db.document("Games/" + gameId + "/Players/" + myPlayer.getName()).updateData([
            "wardLat": coordinate.latitude,
            "wardLong": coordinate.longitude
            ])
    }
    
    override func viewDidLoad() {
        //necessary map stuff
        super.viewDidLoad()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        
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
        
        //get player data
        db.collection("Games/" + gameId + "/Players").getDocuments() { (querySnapshot, error) in
            if let error = error{
                print(error)
            } else {
                //this loop is to check for new players and update existing ones
                //it first updates playerDict, then updates myTeam and otherTeam dicts
                for document in querySnapshot!.documents {
                    if (document.documentID == myPlayer.getName()) {
                        //updates playerDict for myPlayer
                        //instead of setting every time, update this instead
                        self.playerDict[myPlayer.getName()] = myPlayer
                        self.myTeamDict[myPlayer.getName()] = myPlayer
                    } else {
                        let data = document.data()
                        
                        //"this" refers to the current document's location or team, not "this phone's" location or team
                        let thisCoordinate = CLLocationCoordinate2D(latitude: data["lat"] as? Double ?? 0, longitude: data["long"] as? Double ?? 0)
                        let thisWardCoordinate = CLLocationCoordinate2D(latitude: data["wardLat"] as? Double ?? 0, longitude: data["wardLong"] as? Double ?? 0)
                        let thisTeam = data["team"] as? String ?? "none"
                        let thisName = document.documentID
                        
                        //either updates their data or adds them to the dict
                        if self.playerDict.index(forKey: thisName) != nil {
                            if let thisPlayer = self.playerDict[thisName] {
                                thisPlayer.setCoordinate(coordinate: thisCoordinate)
                                thisPlayer.setTeam(team: thisTeam)
                                if (thisWardCoordinate.latitude != 0 || thisWardCoordinate.longitude != 0) {
                                    if (debug) {
                                        thisPlayer.getWard()?.setCoordinate(coordinate: thisWardCoordinate)
                                    }
                                    
                                    if thisPlayer.getWard() == nil {
                                        thisPlayer.addWardAt(coordinate: thisWardCoordinate)
                                    }
                                }
                            }
                        } else {
                            let playerToAdd = Player(name: thisName, team: data["team"] as? String ?? "none", coordinate: thisCoordinate)
                            
                            if (thisWardCoordinate.latitude != 0 || thisWardCoordinate.longitude != 0) {
                                playerToAdd.addWardAt(coordinate: thisWardCoordinate)
                            }
                            
                            self.playerDict[thisName] = playerToAdd
                        }
                        
                        //updates myTeam and otherTeam dicts consider making this run on an update teams button
                        if (thisTeam == myPlayer.getTeam()) {
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
        }
        
        //remove all annotations
        for ann in self.map.annotations{
            self.map.removeAnnotation(ann)
        }
        
        //check for vision and add the annotations
        for key in self.myTeamDict.keys {
            if let thisPlayer = self.myTeamDict[key] {
                self.map.addAnnotation(thisPlayer)
                
                if let ward = thisPlayer.getWard() {
                    self.map.addAnnotation(ward)
                }
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
        //if they're on your team you can see them
        if (playerToCheck.getTeam() == myPlayer.getTeam()) {
            return true
        }
        
        var lat1 : Double
        var lon1 : Double
        let coordToCheck = playerToCheck.getCoordinate()
        let lat2 : Double = coordToCheck.latitude
        let lon2 : Double = coordToCheck.longitude
        
        //loops through every player on your team and checks if that teammate or their ward can see the playerToCheck
        for key in myTeamDict.keys {
            if let thisPlayer = myTeamDict[key] {
                var coord = thisPlayer.getCoordinate()
                lat1 = coord.latitude
                lon1 = coord.longitude
                
                if (latLongDist(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2) < thisPlayer.visionDist) {
                    return true
                }
                
                if let ward = thisPlayer.getWard() {
                    coord = ward.getCoordinate()
                    
                    lat1 = coord.latitude
                    lon1 = coord.longitude
                    
                    if (latLongDist(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2) < ward.visionDist) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    //a function i stole online that tells you the distance in meters between two coordinates
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


