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

class MapViewController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    
    //map
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var ward : UIButton!
    @IBOutlet weak var returnButtonMap : UIButton!
    @IBOutlet weak var death : UIButton!
    
    let manager = CLLocationManager()
    var playerDict: [String: Player] = [myPlayer.getName() : myPlayer] //dictionary of all players
    var deadNames: [String] = [] //list of the names of the dead players on "my" team
    var myPings: [String: Double] = [:] //dict of the names of my pings to their create times. the name is "\(myName)\(pingNum)"
    var respawnPointCoords: [CLLocationCoordinate2D] = []
    var pingNum = 0
    var myTeamPings: [Ping] = [] //list of pings to draw
    var once = false
    var myLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude:0,longitude: 0)
    var x: Float = 0
    var y: Float = 0
    var timer: Timer!
    var colRef: CollectionReference!
    var inDangerStartTime = -1.0
    var respawnEnterTime = -1.0
    let deathTime = 5.0
    let tetherDist = 20.0
    let respawnTime = 15.0
    let respawnDist = 10.0
    @IBOutlet weak var gameIDLabel: UILabel!
    
    override func viewDidLoad() {
        //necessary map stuff
        super.viewDidLoad()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        
        map.delegate = self
        
        //start timer
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(handleData), userInfo: nil, repeats: true)
        
        //ping long press gesture recognizer
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gestureRecognizer:)))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        map.addGestureRecognizer(lpgr)
        
        //gameID label
        gameIDLabel.text = "Game ID: " + gameID
        
        print("col Ref initialized")
        /*[UIView animateWithDuration:0.3f
         animations:^{
         myAnnotation.coordinate = newCoordinate;
         }]*/
        
        //respawn point array
        db.collection("Games/\(gameID)/RespawnPoints").getDocuments() { (querySnapshot, error) in
            if let error = error{
                print(error)
            } else {
                for document in querySnapshot!.documents {
                    let data = document.data()
                    self.respawnPointCoords.append(CLLocationCoordinate2D(latitude: data["lat"] as? Double ?? 0, longitude: data["long"] as? Double ?? 0))
                }
            }
        }
        
        //Change button colors to Player's team color
        if myPlayer.getTeam() == "red" {
            returnButtonMap.setTitleColor(.red, for : .normal)
            ward.setTitleColor(.red, for : .normal)
            death.setTitleColor(.red, for : .normal)
        } else{
            returnButtonMap.setTitleColor(.blue, for : .normal)
            ward.setTitleColor(.blue, for : .normal)
            death.setTitleColor(.blue, for : .normal)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0] //the latest location
        
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
        //set coordinates and death status
        myPlayer.setCoordinate(coordinate: location.coordinate)
        
        db.document("Games/" + gameID + "/Players/" + myPlayer.getName()).updateData([
            "lat": myPlayer.getCoordinate().latitude,
            "long": myPlayer.getCoordinate().longitude,
            ])
    }
    
    @IBAction func dropWard(_ sender: Any) {
        if (!myPlayer.getDead()) {
            myPlayer.addWard()
            let coordinate = myPlayer.getCoordinate()
            
            db.document("Games/" + gameID + "/Players/" + myPlayer.getName()).updateData([
                "wardLat": coordinate.latitude,
                "wardLong": coordinate.longitude
                ])
        }
    }
    
    @IBAction func death(_ sender: Any) {
        if (debug) {
            myPlayer.setDead(dead: !myPlayer.getDead())
        } else {
            myPlayer.setDead(dead: true)
        }
        
        db.document("Games/" + gameID + "/Players/" + myPlayer.getName()).updateData([
            "dead": myPlayer.getDead()
            ])
    }
    
    //ping with long press
    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchLocation = gestureRecognizer.location(in: map)
            let locationCoordinate = map.convert(touchLocation,toCoordinateFrom: map)
            let currTime = CACurrentMediaTime()
            let pingName = "\(myPlayer.getName())\(pingNum)"
            pingNum += 1
            myPings[pingName] = currTime
            
            /*db.document("Games/" + gameID + "/Pings/" + pingName).updateData([
                "lat": locationCoordinate.latitude,
                "long": locationCoordinate.longitude,
                "team": myPlayer.getTeam()
                ])*/
        }
    }
    
    @objc func handleData() {
        getData()
        step()
        //sendData()
    }
    
    //i'm using getData() basically like the update function in unity
    func getData() {
        //eventually make a server app that calculates vision so that the clients don't have access to all the enemies' positions
        
        //get player data
        db.collection("Games/" + gameID + "/Players").getDocuments() { (querySnapshot, error) in
            if let error = error{
                print(error)
            } else {
                //this loop is to check for new players and update existing ones
                //it first updates playerDict, then updates myTeam and otherTeam dicts
                for document in querySnapshot!.documents {
                    if (document.documentID != myPlayer.getName()) {
                        let data = document.data()
                        
                        //"this" refers to the current document's location or team, not "this phone's" location or team
                        let thisName = document.documentID
                        let thisDead = data["dead"] as? Bool ?? true
                        let thisCoordinate = CLLocationCoordinate2D(latitude: data["lat"] as? Double ?? 0, longitude: data["long"] as? Double ?? 0)
                        let thisWardCoordinate = CLLocationCoordinate2D(latitude: data["wardLat"] as? Double ?? 0, longitude: data["wardLong"] as? Double ?? 0)
                        let thisTeam = data["team"] as? String ?? "none"
                        
                        //either updates their data or adds them to the playerDict
                        if self.playerDict.index(forKey: thisName) != nil {
                            if let thisPlayer = self.playerDict[thisName] {
                                thisPlayer.setCoordinate(coordinate: thisCoordinate)
                                thisPlayer.setTeam(team: thisTeam)
                                thisPlayer.setDead(dead: thisDead)
                                
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
                    }
                }
            }
        }
    }
    
    func step() {
        //RESPAWN
        let currTime = CACurrentMediaTime()
        
        if (inRespawnArea()) {
            if (currTime > respawnEnterTime + respawnTime) {
                myPlayer.setDead(dead: false)
            }
        } else {
            respawnEnterTime = currTime
        }
        
        //RAY COMBAT
        
        //ADDING ANNOTATIONS
        let annArray = map.annotations
        
        //add myTeam's annotations
        for thisName in playerDict.keys {
            if let thisPlayer = playerDict[thisName] {
                if (thisPlayer.getTeam() != myPlayer.getTeam()) {
                    continue
                }
                
                var playerOnMap: Bool = false
                var wardOnMap: Bool = false
                let thisDead = thisPlayer.getDead()
                
                for ann in annArray {
                    if (thisPlayer.title == ann.title) {
                        playerOnMap = true
                    }
                    
                    if let thisWard = thisPlayer.getWard() {
                        if (thisWard.getName() == ann.title) {
                            wardOnMap = true
                        }
                    }
                }
                
                if (!playerOnMap && !thisDead) {
                    map.addAnnotation(thisPlayer)
                }
                
                if (playerOnMap && thisDead) {
                    map.removeAnnotation(thisPlayer)
                }
                
                if (!wardOnMap) {
                    if let thisWard = thisPlayer.getWard() {
                        map.addAnnotation(thisWard)
                    }
                }
            }
        }
        
        //add other team annotations
        for thisName in playerDict.keys {
            if let thisPlayer = playerDict[thisName] {
                if (thisPlayer.getTeam() == myPlayer.getTeam()) {
                    continue
                }
                
                var playerOnMap: Bool = false
                let thisDead = thisPlayer.getDead()
                let visible = self.hasVisionOf(playerToCheck: thisPlayer)
                
                for ann in annArray {
                    if (thisPlayer.title == ann.title) {
                        playerOnMap = true
                    }
                }
                
                if (!playerOnMap && (!thisDead && visible)) {
                    map.addAnnotation(thisPlayer)
                    print(thisPlayer.title as Any)
                }
                
                if (playerOnMap && (thisDead || !visible)) {
                    map.removeAnnotation(thisPlayer)
                }
            }
        }
        
        //DRAW MKMAPOVERLAYS
        //draw rays based on a dict
        //draw circles around each player and ward in myTeamDict for vision OR just wards if we're doing that
    }
    
    func existsInDict(annTitleToCheck: String) -> Bool {
        for thisName in playerDict.keys {
            if let thisPlayer = playerDict[thisName] {
                if (thisPlayer.title == annTitleToCheck) {
                    return true
                }
                
                if let thisWard = thisPlayer.getWard() {
                    if (thisWard.title == annTitleToCheck) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    func hasVisionOf(playerToCheck: Player) -> Bool {
        //if they're on your team you can see them
        if (playerToCheck.getTeam() == myPlayer.getTeam()) {
            return true
        }
        
        let coordToCheck = playerToCheck.getCoordinate()
        let lat2 : Double = coordToCheck.latitude
        let lon2 : Double = coordToCheck.longitude
        
        //loops through every player on your team and checks if that teammate or their ward can see the playerToCheck
        for thisName in playerDict.keys {
            if let thisPlayer = playerDict[thisName] {
                if (thisPlayer.getTeam() != myPlayer.getTeam()) {
                    continue
                }
                
                let coord = thisPlayer.getCoordinate()
                let lat1 = coord.latitude
                let lon1 = coord.longitude
                
                if (!thisPlayer.getDead() && latLongDist(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2) < thisPlayer.visionDist) {
                    return true
                }
                
                if let ward = thisPlayer.getWard() {
                    let wardCoord = ward.getCoordinate()
                    
                    let lat1 = wardCoord.latitude
                    let lon1 = wardCoord.longitude
                    
                    if (latLongDist(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2) < ward.visionDist) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    func inRespawnArea() -> Bool {
        for coord in respawnPointCoords {
            let myCoord = myPlayer.getCoordinate()
            let lat1 = myCoord.latitude
            let lon1 = myCoord.longitude
            let lat2 = coord.latitude
            let lon2 = coord.longitude
            
            if (latLongDist(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2) < respawnDist) {
                return true
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


extension MapViewController: MKMapViewDelegate{

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Entity")
        if annotationView == nil{
            annotationView = MKAnnotationView.init(annotation: annotation, reuseIdentifier: "Entity")
        }
        
        if let annotation = annotation as? Player{
            if annotation.getTeam() == "red" {
                annotationView?.image = UIImage(named: "Red Player")
                let name = UILabel(frame: CGRect(x: 0, y: -16, width: 20, height: 8))
                name.textAlignment = .center
                name.font = UIFont(name: "Rockwell", size: 6)
                annotationView?.addSubview(name)
            }
            if annotation.getTeam() == "blue" {
                annotationView?.image = UIImage(named: "Blue Player")
            }
        }
        if let annotation = annotation as? Ward{
            if annotation.getTeam() == "red" {
                annotationView?.image = UIImage(named: "Red Ward")
            }
            if annotation.getTeam() == "blue" {
                annotationView?.image = UIImage(named: "Blue Ward")
            }
        }
        annotationView?.canShowCallout = true
        return annotationView
    }

}
