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

var mapViewController: MapViewController!

class MapViewController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    
    //ib outlets
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var ward : UIButton!
    @IBOutlet weak var returnButtonMap : UIButton!
    @IBOutlet weak var death : UIButton!
    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var redPtLabel: UILabel!
    @IBOutlet weak var bluePtLabel: UILabel!
    
    //other vars
    let manager = CLLocationManager()
    var playerDict: [String: Player] = [myPlayer.getName() : myPlayer] //dictionary of all players
    var deadNames: [String] = [] //list of the names of the dead players on "my" team
    var myPings: [String: Double] = [:] //dict of the names of my pings to their create times. the name is "\(myName)\(pingNum)"
    var respawnPoints: [RespawnPoint] = []
    var border: BorderOverlay = BorderOverlay()
    var boords: [CLLocation] = []
    var pingNum = 0
    var handleDataCounter = 0
    var myTeamPings: [Ping] = [] //list of pings to draw
    var once = false
    var myLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude:0,longitude: 0)
    var x: Float = 0
    var y: Float = 0
    var inDangerStartTime = -1.0
    var respawnEnterTime = -1.0
    @IBOutlet weak var gameIDLabel: UILabel!
    var cps = [ControlPoint]() //collection of control points - date retrieve from server
    var isSpec = false
    let mapViewDelegate = MapViewDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //map stuff
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        mapViewController = self
        map.delegate = mapViewDelegate
        
        //check if spectator
        if (myPlayer.getName() == ".SPECTATOR") {
            isSpec = true
        }
        
        //retrieve data of control point from server
        getCPData()
        
        //start step function timer
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(step), userInfo: nil, repeats: true)
        
        //ping long press gesture recognizer
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gestureRecognizer:)))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        map.addGestureRecognizer(lpgr)
        
        //Labels
        gameIDLabel.text = "Game ID: " + gameID
        redPtLabel.text = "red: 0"
        bluePtLabel.text = "blue: 0"
        
        if (!debug) {
            debugLabel.text = ""
        }
        
        print("col Ref initialized")
        /*[UIView animateWithDuration:0.3f
         animations:^{
         myAnnotation.coordinate = newCoordinate;
         }]*/
        
        //respawn point array
        db.collection("\(gameCol)/\(gameID)/RespawnPoints").getDocuments() { (querySnapshot, error) in
            if let error = error{
                print(error)
            } else {
                for document in querySnapshot!.documents {
                    let data = document.data()
                    let name = document.documentID
                    let coordinate = CLLocationCoordinate2D(latitude: data["lat"] as? Double ?? 0, longitude: data["long"] as? Double ?? 0)
                    let point = RespawnPoint(name: name, coordinate: coordinate)
                    self.respawnPoints.append(point)
                    self.map.addAnnotation(point)
                }
            }
        }
        
        if (debug) {
            respawnTime = 5.0
        }
        
        //Change button colors to Player's team color
        if myPlayer.getTeam() == "red" {
            returnButtonMap.setTitleColor(.red, for : .normal)
            ward.setTitleColor(.red, for : .normal)
            death.setTitleColor(.red, for : .normal)
        } else if myPlayer.getTeam() == "blue" {
            returnButtonMap.setTitleColor(.blue, for : .normal)
            ward.setTitleColor(.blue, for : .normal)
            death.setTitleColor(.blue, for : .normal)
        } else { //a spectator
            returnButtonMap.setTitleColor(.gray, for : .normal)
            ward.setTitleColor(.gray, for : .normal)
            death.setTitleColor(.gray, for : .normal)
        }
        
        //add myPlayer to playerDict
        playerDict[myPlayer.getName()] = myPlayer
        
        //send data
        networking.sendTeam(team: myPlayer.getTeam())
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
            
            if (!isSpec) {
                self.map.showsUserLocation = true
            } else {
                self.map.showsUserLocation = false
                myPlayer.setCoordinate(coordinate: CLLocationCoordinate2D(latitude: 200, longitude: 200))
                networking.sendLocation(coord: myPlayer.getCoordinate())
            }
            
            once = true
        }
        
        //write data
        //set coordinates and death status
        if (!isSpec) {
            myPlayer.setCoordinate(coordinate: location.coordinate)
            networking.sendLocation(coord: myPlayer.getCoordinate())
        }
    }
    
    @IBAction func onReturnPressed(_ sender: Any) {
        if (true/*!debug*/) {
            //tell server
            networking.sendRet()
        }
        
        manager.stopUpdatingLocation()
        self.performSegue(withIdentifier: "ShowName", sender: nil)
    }
    
    @IBAction func dropWard(_ sender: Any) {
        if (!myPlayer.getDead()) {
            let coordinate = myPlayer.getCoordinate()
            
            if let myWard = myPlayer.getWard() {
                map.removeAnnotation(myWard)
            }
            
            myPlayer.addWardAt(coordinate: coordinate)
            networking.sendWardLoc(coord: coordinate)
        }
    }
    
    @IBAction func death(_ sender: Any) {
        if (debug) {
            myPlayer.setDead(dead: !myPlayer.getDead())
        } else {
            myPlayer.setDead(dead: true)
        }
        
        networking.sendDead(dead: myPlayer.getDead())
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
        }
    }
    
    @objc func step() {
        let state = UIApplication.shared.applicationState
        var callStepActions = false
        
        if (state == .active) {
            callStepActions = true
        } else {
            if (handleDataCounter > 8) {
                callStepActions = true
                handleDataCounter = 0
            } else {
                handleDataCounter += 1
            }
        }
        
        if (callStepActions) {
            stepActions()
        }
        
        //make sure to send a heartbeat every second regardless
        networking.sendHeartbeat()
    }
    
    func stepActions() {
        //testing/printing
        if (debug) {
            var gameStateString = ""
            
            for thisName in playerDict.keys {
                if let thisPlayer = playerDict[thisName] {
                    let thisCoord = thisPlayer.getCoordinate()
                    
                    gameStateString += "\(thisPlayer.getName()) c:\(thisPlayer.getConnected()) \(thisPlayer.getTeam()) d:\(thisPlayer.getDead()) \(String(format: "%.5f", thisCoord.latitude)) \(String(format: "%.5f", thisCoord.longitude))"
                    
                    if let thisWard = thisPlayer.getWard() {
                        let thisWardCoord = thisWard.getCoordinate()
                        
                        gameStateString += " \(String(format: "%.5f", thisWardCoord.latitude)) \(String(format: "%.5f", thisWardCoord.longitude))"
                    } else {
                        gameStateString += " no ward"
                    }
                    
                    gameStateString += "\n"
                } else {
                    print("player of name \(thisName) is not in playerDict")
                }
            }
            
            debugLabel.text = gameStateString
        }
        
        //server stuff every second
        networking.readAllData()
        networking.sendReceiving()
        
        //RESPAWN
        let currTime = CACurrentMediaTime()
        
        if (myPlayer.getDead()) {
            if (inRespawnArea()) {
                if (currTime > respawnEnterTime + respawnTime) {
                    myPlayer.setDead(dead: false)
                    networking.sendDead(dead: false)
                }
                
                print("in respawn area")
            } else {
                respawnEnterTime = currTime
            }
        } else {
            respawnEnterTime = currTime
        }
        
        //RAY COMBAT
        
        //ADDING ANNOTATIONS
        //fill array of what annotations should be present
        var targetAnnDict: [String: MKAnnotation] = [:]
        
        //objectives
        for rp in respawnPoints {
            targetAnnDict[rp.getName()] = rp
        }
        
        //my team
        for thisName in playerDict.keys {
            if let thisPlayer = playerDict[thisName] {
                if (thisPlayer.getConnected() && thisPlayer.getTeam() == myPlayer.getTeam()) {
                    //getDead is separate because you draw wards of dead players
                    if (!thisPlayer.getDead()) {
                        targetAnnDict[thisName] = thisPlayer
                    }
                    
                    if let thisWard = thisPlayer.getWard() {
                        targetAnnDict[thisWard.getName()] = thisWard
                    }
                }
            }
        }
        
        //enemy team
        for thisName in playerDict.keys {
            if let thisPlayer = playerDict[thisName] {
                if (thisPlayer.getConnected() && thisPlayer.getTeam() != myPlayer.getTeam() && (hasVisionOf(playerToCheck: thisPlayer) || isSpec)) {
                    //getDead is separate in case we wanna draw enemy wards later on
                    if (!thisPlayer.getDead()) {
                        targetAnnDict[thisName] = thisPlayer
                    }
                }
                
                if (isSpec) {
                    if let thisWard = thisPlayer.getWard() {
                        targetAnnDict[thisWard.getName()] = thisWard
                    }
                }
            }
        }
        
        //add annotations that aren't currently present but need to be
        let currAnnArray = map.annotations
        
        for thisAnnName in targetAnnDict.keys {
            if let thisAnn = targetAnnDict[thisAnnName] {
                var thisAnnCurrPresent = false
                
                for ann in currAnnArray {
                    if (thisAnnName == ann.title) {
                        thisAnnCurrPresent = true
                    }
                }
                
                if (!thisAnnCurrPresent) {
                    map.addAnnotation(thisAnn)
                }
            }
        }
        
        //remove annotations that are currently present but shouldn't be
        for thisAnn in currAnnArray {
            var thisAnnInTarget = false
            
            for annName in targetAnnDict.keys {
                if (annName == thisAnn.title) {
                    thisAnnInTarget = true
                }
            }
            
            if (!thisAnnInTarget) {
                map.removeAnnotation(thisAnn)
            }
        }
        
        //DRAW MKMAPOVERLAYS
        //draw rays based on a dict
        //draw circles around each player and ward in myTeamDict for vision OR just wards if we're doing that
        
        //Check if player is in the CP radius
        for cp in self.cps{
            if !cp.getStay() {      //skip section if player is staying in a control point
                var incAmt : Int = 0
                if cp.inArea(myPlayer: myPlayer) && !myPlayer.getDead(){
                    cp.setStay(s: true) //indicate that the player has already entered the area
                    incAmt = 1
                } else{ //if player left the cp or is dead
                    incAmt = -1
                }
                
                //update number of player in the control point if player leaves or enters the control point
                //if player is in radius, update number in server
                if myPlayer.getTeam() == "red"{
                    cp.addNumRed(num: incAmt)
                    redPtLabel.text = "red: " + String(cp.getRedPoints())   //update red points on mapView
                    networking.sendRedPoint(point: cp.getRedPoints())
                    //print("updated numRed in server")
                } else if myPlayer.getTeam() == "red"{
                    cp.addNumBlue(num: incAmt)
                    bluePtLabel.text = "blue: " + String(cp.getBluePoints())   //update blue points on mapView
                    networking.sendBluePoint(point: cp.getBluePoints())
                    //print("updated numBlue in server")
                }
                networking.sendCP(numRed: cp.getNumRed(), numBlue: cp.getNumBlue())
                
                //add points to team: 1 point per second to the team cp belongs to
            }
        }
    }
    
    //retrieve control point from server
    func getCPData(){
        //print("getting CP data from server")
        
        /* firebase code
         //initialize ControlPoint
         db.collection("\(gameCol)/\(gameID)/CP").getDocuments() { (querySnapshot, error) in
         if let error = error{
         print(error)
         } else {
         //print("CP server collection path valid")
         //this loop is to check for new players and update existing ones
         //it first updates playerDict, then updates myTeam and otherTeam dicts
         for document in querySnapshot!.documents {
         var cpExist : Bool = false
         for cp in self.cps {
         if cp.getID() == document.documentID{
         cpExist = true
         }
         }
         if(!cpExist){
         let newCP = ControlPoint()
         let data = document.data()
         newCP.setNumRed(numRed: data["numRed"] as? Int ?? 0)
         newCP.setNumBlue(numBlue: data["numBlue"] as? Int ?? 0)
         newCP.setID(id: document.documentID)
         newCP.setCoordinate(coordinate: CLLocationCoordinate2D(latitude: data["lat"] as? Double ?? 0, longitude: data["long"] as? Double ?? 0))
         newCP.setTeam(team: data["team"] as? String ?? "")
         newCP.setName(name: document.documentID)
         newCP.setRadius(radius: data["radius"] as? Double ?? 0)
         
         //retrieve points for each team
         db.collection("\(gameCol)/\(gameID)/Points").getDocuments() { (querySnapshot, error) in
         if let error = error{
         print(error)
         } else {
         for document in querySnapshot!.documents {
         if document.documentID == "Red"{
         newCP.setRedPoints(point: document.data()["points"] as! Double)
         } else{
         newCP.setBluePoints(point: document.data()["points"] as! Double)
         }
         }
         }
         }
         
         self.cps.append(newCP)
         
         //put CP on map
         newCP.title = newCP.getName()
         
         
         //print("New CP added: " + newCP.getID())
         //print("new CP location: " + String(newCP.getLocation().latitude))
         }
         }
         }
         }
         */
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
        //if you're the spectator return true
        if (isSpec) {
            return true
        }
        
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
                if (!thisPlayer.getConnected() || thisPlayer.getTeam() != myPlayer.getTeam()) {
                    continue
                }
                
                let coord = thisPlayer.getCoordinate()
                let lat1 = coord.latitude
                let lon1 = coord.longitude
                
                if (!thisPlayer.getDead() && latLongDist(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2) < thisPlayer.visionDist) {
                    //return true
                }
                
                if let ward = thisPlayer.getWard() {
                    let wardCoord = ward.getCoordinate()
                    
                    let lat1 = wardCoord.latitude
                    let lon1 = wardCoord.longitude
                    
                    if (latLongDist(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2) < wardVisionDist) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    func inRespawnArea() -> Bool {
        for point in respawnPoints {
            let myCoord = myPlayer.getCoordinate()
            let pointCoord = point.getCoordinate()
            let lat1 = myCoord.latitude
            let lon1 = myCoord.longitude
            let lat2 = pointCoord.latitude
            let lon2 = pointCoord.longitude
            
            if (latLongDist(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2) < respawnDist) {
                return true
            }
        }
        
        return false
    }
    
    //a new borderOverlay has to be created everytime because you can't add new points to an mkpolygon. also, the boords have to be sent individually because if they were all sent as once as a list of coordinates after "boords" we don't know how much to increment when receiving "boords". even if we have a length value right after boords like "boords:5:[coordinates]", it would crash if there is no integer right after boords
    func addBoord(boord: CLLocation) {
        map.removeOverlay(border)
        boords.append(boord)
        border = BorderOverlay(vertices: boords)
        map.addOverlay(border)
    }
    
    func addRP(name: String, coordinate: CLLocationCoordinate2D) {
        let point = RespawnPoint(name: name, coordinate: coordinate)
        respawnPoints.append(point)
        map.addAnnotation(point)
    }
    
    func updatePlayerTeam(name: String, team: String) {
        if let thisPlayer = playerDict[name] {
            let oldTeam = thisPlayer.getTeam()
            thisPlayer.setTeam(team: team)
            
            if let thisWard = thisPlayer.getWard() {
                thisWard.setTeam(team: team)
                
                //the old ward circle needs to be removed here because mapView is only called on adding
                if let thisOverlay = thisWard.getOverlay() {
                    map.removeOverlay(thisOverlay)
                }
            }
            
            //have to remove annotation after setting team so the mapView function has the correct info
            if (team != oldTeam) {
                map.removeAnnotation(thisPlayer)
            }
        }
    }
    
    func updatePlayerLoc(name: String, lat: Double, long: Double) {
        if let thisPlayer = playerDict[name] {
            if (thisPlayer.getConnected()) {
                thisPlayer.setCoordinate(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long))
            }
        }
    }
    
    func updatePlayerDead(name: String, dead: Bool) {
        if let thisPlayer = playerDict[name] {
            thisPlayer.setDead(dead: dead)
        }
    }
    
    func updatePlayerWardLoc(name: String, lat: Double, long: Double) {
        print("updatePlayerWardLoc called")
        
        if let thisPlayer = playerDict[name] {
            //this annotation needs to be removed here so that a new ward circle is drawn
            if let thisWard = thisPlayer.getWard() {
                map.removeAnnotation(thisWard)
                
                //the old ward circle needs to be removed here because mapView is only called on adding
                if let thisOverlay = thisWard.getOverlay() {
                    map.removeOverlay(thisOverlay)
                }
            }
            
            thisPlayer.addWardAt(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long))
        }
    }
    
    func updatePlayerConn(name: String, conn: Bool) {
        if let thisPlayer = playerDict[name] {
            if (!conn) {
                thisPlayer.setConnected(connected: conn)
                
                if let thisWard = thisPlayer.getWard() {
                    //the old ward circle needs to be removed here because mapView is only called on adding
                    if let thisOverlay = thisWard.getOverlay() {
                        map.removeOverlay(thisOverlay)
                    }
                }
            }
        }
        
        if (conn) {
            //creating a new player whenever conn is true is fine because in the server i will only send conn as true if it's part of a "new player package". if conn is sent by itself it is always false (i think)
            ///wrong arguments below
            //maybe a new player should be created regardless of what conn is, just whenever a conn update is attempted. this is wrong because if conn is false you need to preserve the old player to know that conn is false cuz a new player has a default conn of true
            //maybe a new player should only be created if conn is changed, either from false to true or true to false. this is wrong because a new player of the same name could've connected within a second of an old one disconnecting, resulting in the server only sending conn true for this player name. in this case, conn stays at true but a new player needs to be created
            let newPlayer = Player(name: name, team: "none", coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
            playerDict[name] = newPlayer
        }
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}


////
////  ViewController.swift
////  Test
////
////  Created by Ethan Soo on 6/19/18.
////  Copyright © 2018 Ethan Soo. All rights reserved.
////
//
//import UIKit
//import MapKit
//import CoreLocation
//import Firebase
//
//var mapViewController: MapViewController!
//
//class MapViewController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
//
//    //ib outlets
//    @IBOutlet weak var map: MKMapView!
//    @IBOutlet weak var ward : UIButton!
//    @IBOutlet weak var returnButtonMap : UIButton!
//    @IBOutlet weak var death : UIButton!
//    @IBOutlet weak var debugLabel: UILabel!
//    @IBOutlet weak var redPtLabel: UILabel!
//    @IBOutlet weak var bluePtLabel: UILabel!
//
//    //other vars
//    let manager = CLLocationManager()
//    var playerDict: [String: Player] = [myPlayer.getName() : myPlayer] //dictionary of all players
//    var deadNames: [String] = [] //list of the names of the dead players on "my" team
//    var myPings: [String: Double] = [:] //dict of the names of my pings to their create times. the name is "\(myName)\(pingNum)"
//    var respawnPoints: [RespawnPoint] = []
//    var border: BorderOverlay = BorderOverlay()
//    var boords: [CLLocation] = []
//    var pingNum = 0
//    var handleDataCounter = 0
//    var myTeamPings: [Ping] = [] //list of pings to draw
//    var once = false
//    var myLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude:0,longitude: 0)
//    var x: Float = 0
//    var y: Float = 0
//    var inDangerStartTime = -1.0
//    var respawnEnterTime = -1.0
//    @IBOutlet weak var gameIDLabel: UILabel!
//    var cps = [ControlPoint]() //collection of control points - date retrieve from server
//    var isSpec = false
//    let mapViewDelegate = MapViewDelegate()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        //map stuff
//        manager.delegate = self
//        manager.desiredAccuracy = kCLLocationAccuracyBest
//        manager.requestWhenInUseAuthorization()
//        manager.startUpdatingLocation()
//        manager.allowsBackgroundLocationUpdates = true
//        manager.pausesLocationUpdatesAutomatically = false
//        mapViewController = self
//        map.delegate = mapViewDelegate
//
//        //check if spectator
//        if (myPlayer.getName() == ".SPECTATOR") {
//            isSpec = true
//        }
//
//        //retrieve data of control point from server
//        getCPData()
//
//        //start step function timer
//        timer.invalidate()
//        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(handleData), userInfo: nil, repeats: true)
//
//        //ping long press gesture recognizer
//        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gestureRecognizer:)))
//        lpgr.minimumPressDuration = 0.5
//        lpgr.delaysTouchesBegan = true
//        lpgr.delegate = self
//        map.addGestureRecognizer(lpgr)
//
//        //Labels
//        gameIDLabel.text = "Game ID: " + gameID
//
//        if (!debug) {
//            debugLabel.text = ""
//        }
//
//        print("col Ref initialized")
//        /*[UIView animateWithDuration:0.3f
//         animations:^{
//         myAnnotation.coordinate = newCoordinate;
//         }]*/
//
//        //respawn point array
//        db.collection("\(gameCol)/\(gameID)/RespawnPoints").getDocuments() { (querySnapshot, error) in
//            if let error = error{
//                print(error)
//            } else {
//                for document in querySnapshot!.documents {
//                    let data = document.data()
//                    let name = document.documentID
//                    let coordinate = CLLocationCoordinate2D(latitude: data["lat"] as? Double ?? 0, longitude: data["long"] as? Double ?? 0)
//                    let point = RespawnPoint(name: name, coordinate: coordinate)
//                    self.respawnPoints.append(point)
//                    self.map.addAnnotation(point)
//                }
//            }
//        }
//
//        if (debug) {
//            respawnTime = 5.0
//        }
//
//        //Change button colors to Player's team color
//        if myPlayer.getTeam() == "red" {
//            returnButtonMap.setTitleColor(.red, for : .normal)
//            ward.setTitleColor(.red, for : .normal)
//            death.setTitleColor(.red, for : .normal)
//        } else if myPlayer.getTeam() == "blue" {
//            returnButtonMap.setTitleColor(.blue, for : .normal)
//            ward.setTitleColor(.blue, for : .normal)
//            death.setTitleColor(.blue, for : .normal)
//        } else{ //a spectator
//            returnButtonMap.setTitleColor(.gray, for : .normal)
//            ward.setTitleColor(.gray, for : .normal)
//            death.setTitleColor(.gray, for : .normal)
//        }
//
//        //add myPlayer to playerDict
//        playerDict[myPlayer.getName()] = myPlayer
//
//        //send data
//        networking.sendTeam(team: myPlayer.getTeam())
//    }
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        let location = locations[0] //the latest location
//
//        if (!once){
//            //i'm not sure how this works someone pls comment - patrick
//            let span: MKCoordinateSpan = MKCoordinateSpan.init(latitudeDelta: 0.01, longitudeDelta: 0.01)
//            myLocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
//            let region:MKCoordinateRegion = MKCoordinateRegion.init(center: myLocation, span: span)
//            map.setRegion(region, animated: true)
//            print(location.coordinate.latitude, " and ", location.coordinate.longitude)
//
//            if (!isSpec) {
//                self.map.showsUserLocation = true
//            } else {
//                self.map.showsUserLocation = false
//                myPlayer.setCoordinate(coordinate: CLLocationCoordinate2D(latitude: 200, longitude: 200))
//                networking.sendLocation(coord: myPlayer.getCoordinate())
//            }
//
//            once = true
//        }
//
//        //write data
//        //set coordinates and death status
//        if (!isSpec) {
//            myPlayer.setCoordinate(coordinate: location.coordinate)
//            networking.sendLocation(coord: myPlayer.getCoordinate())
//        }
//    }
//
//    @IBAction func onReturnPressed(_ sender: Any) {
//        if (true || !debug) {
//            //tell server
//            networking.sendRet()
//        }
//
//        self.performSegue(withIdentifier: "ShowName", sender: nil)
//    }
//
//    @IBAction func dropWard(_ sender: Any) {
//        if (!myPlayer.getDead()) {
//            let coordinate = myPlayer.getCoordinate()
//
//            if let myWard = myPlayer.getWard() {
//                map.removeAnnotation(myWard)
//            }
//
//            myPlayer.addWardAt(coordinate: coordinate)
//            networking.sendWardLoc(coord: coordinate)
//        }
//    }
//
//    @IBAction func death(_ sender: Any) {
//        if (debug) {
//            myPlayer.setDead(dead: !myPlayer.getDead())
//        } else {
//            myPlayer.setDead(dead: true)
//        }
//
//        networking.sendDead(dead: myPlayer.getDead())
//    }
//
//    //ping with long press
//    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
//        if gestureRecognizer.state == UIGestureRecognizer.State.began {
//            let touchLocation = gestureRecognizer.location(in: map)
//            let locationCoordinate = map.convert(touchLocation,toCoordinateFrom: map)
//            let currTime = CACurrentMediaTime()
//            let pingName = "\(myPlayer.getName())\(pingNum)"
//            pingNum += 1
//            myPings[pingName] = currTime
//        }
//    }
//
//    @objc func handleData() {
//        let state = UIApplication.shared.applicationState
//        var callStep = false
//
//        if (state == .active) {
//            callStep = true
//        } else {
//            if (handleDataCounter > 8) {
//                callStep = true
//                handleDataCounter = 0
//            } else {
//                handleDataCounter += 1
//            }
//        }
//
//        if (callStep) {
//            step()
//        }
//
//        //make sure to send a heartbeat every second regardless
//        networking.sendHeartbeat()
//    }
//
//    func step() {
//        //testing/printing
//        if (debug) {
//            var gameStateString = ""
//
//            for thisName in playerDict.keys {
//                if let thisPlayer = playerDict[thisName] {
//                    let thisCoord = thisPlayer.getCoordinate()
//
//                    gameStateString += "\(thisPlayer.getName()) c:\(thisPlayer.getConnected()) \(thisPlayer.getTeam()) d:\(thisPlayer.getDead()) \(String(format: "%.5f", thisCoord.latitude)) \(String(format: "%.5f", thisCoord.longitude))"
//
//                    if let thisWard = thisPlayer.getWard() {
//                        let thisWardCoord = thisWard.getCoordinate()
//
//                        gameStateString += " \(String(format: "%.5f", thisWardCoord.latitude)) \(String(format: "%.5f", thisWardCoord.longitude))"
//                    } else {
//                        gameStateString += " no ward"
//                    }
//
//                    gameStateString += "\n"
//                } else {
//                    print("player of name \(thisName) is not in playerDict")
//                }
//            }
//
//            debugLabel.text = gameStateString
//        }
//
//        //server stuff every second
//        networking.readAllData()
//        networking.sendReceiving()
//
//        //RESPAWN
//        let currTime = CACurrentMediaTime()
//
//        if (myPlayer.getDead()) {
//            if (inRespawnArea()) {
//                if (currTime > respawnEnterTime + respawnTime) {
//                    myPlayer.setDead(dead: false)
//                    networking.sendDead(dead: false)
//                }
//
//                print("in respawn area")
//            } else {
//                respawnEnterTime = currTime
//            }
//        } else {
//            respawnEnterTime = currTime
//        }
//
//        //RAY COMBAT
//
//        //ADDING ANNOTATIONS
//        //fill array of what annotations should be present
//        var targetAnnDict: [String: MKAnnotation] = [:]
//
//        //objectives
//        for rp in respawnPoints {
//            targetAnnDict[rp.getName()] = rp
//        }
//
//        //my team
//        for thisName in playerDict.keys {
//            if let thisPlayer = playerDict[thisName] {
//                if (thisPlayer.getConnected() && thisPlayer.getTeam() == myPlayer.getTeam()) {
//                    //getDead is separate because you draw wards of dead players
//                    if (!thisPlayer.getDead()) {
//                        targetAnnDict[thisName] = thisPlayer
//                    }
//
//                    if let thisWard = thisPlayer.getWard() {
//                        targetAnnDict[thisWard.getName()] = thisWard
//                    }
//                }
//            }
//        }
//
//        //enemy team
//        for thisName in playerDict.keys {
//            if let thisPlayer = playerDict[thisName] {
//                if (thisPlayer.getConnected() && thisPlayer.getTeam() != myPlayer.getTeam() && (hasVisionOf(playerToCheck: thisPlayer) || isSpec)) {
//                    //getDead is separate in case we wanna draw enemy wards later on
//                    if (!thisPlayer.getDead()) {
//                        targetAnnDict[thisName] = thisPlayer
//                    }
//                }
//
//                if (isSpec) {
//                    if let thisWard = thisPlayer.getWard() {
//                        targetAnnDict[thisWard.getName()] = thisWard
//                    }
//                }
//            }
//        }
//
//        //add annotations that aren't currently present but need to be
//        let currAnnArray = map.annotations
//
//        for thisAnnName in targetAnnDict.keys {
//            if let thisAnn = targetAnnDict[thisAnnName] {
//                var thisAnnCurrPresent = false
//
//                for ann in currAnnArray {
//                    if (thisAnnName == ann.title) {
//                        thisAnnCurrPresent = true
//                    }
//                }
//
//                if (!thisAnnCurrPresent) {
//                    map.addAnnotation(thisAnn)
//                }
//            }
//        }
//
//        //remove annotations that are currently present but shouldn't be
//        for thisAnn in currAnnArray {
//            var thisAnnInTarget = false
//
//            for annName in targetAnnDict.keys {
//                if (annName == thisAnn.title) {
//                    thisAnnInTarget = true
//                }
//            }
//
//            if (!thisAnnInTarget) {
//                map.removeAnnotation(thisAnn)
//            }
//        }
//
//        //DRAW MKMAPOVERLAYS
//        //draw rays based on a dict
//        //draw circles around each player and ward in myTeamDict for vision OR just wards if we're doing that
//
//        //Check if player is in the CP radius
//        for cp in self.cps{
////<<<<<<< HEAD
////            if !cp.getStay() {      //skip section if player is staying in a control point
////                var incAmt : Int = 0
////                if cp.inArea(myPlayer: myPlayer) && !myPlayer.getDead(){
////                    cp.setStay(s: true) //indicate that the player has already entered the area
////                    incAmt = 1
////                } else{ //if player left the cp or is dead
////                    incAmt = -1
////                }
////
////                //update number of player in the control point if player leaves or enters the control point
////                //if player is in radius, update number in server
////                if myPlayer.getTeam() == "red"{
////                    cp.addNumRed(num: incAmt)
////                    redPtLabel.text = "red: " + String(cp.getRedPoints())   //update red points on mapView
////                    networking.sendRedPoint(point: cp.getRedPoints())
////                    //print("updated numRed in server")
////                } else if myPlayer.getTeam() == "red"{
////                    cp.addNumBlue(num: incAmt)
////                    bluePtLabel.text = "blue: " + String(cp.getBluePoints())   //update blue points on mapView
////                    networking.sendBluePoint(point: cp.getBluePoints())
////                    //print("updated numBlue in server")
////                }
////                networking.sendCPNums(numRed: cp.getNumRed(), numBlue: cp.getNumBlue())
////
////                //add points to team: 1 point per second to the team cp belongs to
////=======
//            var incAmt : Int = 0
//            if cp.inArea(myPlayer: myPlayer) && !cp.getStay(){
//                cp.setStay(s: true) //indicate that the player has already entered the area
//                incAmt = 1
//            } else{
//                incAmt = -1
//            }
//
//            //update number of player in the control point if player leaves or enters the control point
//            //if player is in radius, update number in server
//            if myPlayer.getTeam() == "red"{
//                cp.addNumRed(num: incAmt)
//                //print("updated numRed in server")
//            } else if myPlayer.getTeam() == "red"{
//                cp.addNumBlue(num: incAmt)
//                //print("updated numBlue in server")
////>>>>>>> parent of fcc4ddd... Merge branch 'master' of https://github.com/GWCMelody/GameMap
//            }
//
//            //add points to team: 1 point per second to the team cp belongs to
//        }
//
//    }
//
//    //retrieve control point from server
//    func getCPData(){
//        //print("getting CP data from server")
//
//
///* firebase code
//=======
//>>>>>>> parent of fcc4ddd... Merge branch 'master' of https://github.com/GWCMelody/GameMap
//        //initialize ControlPoint
//        db.collection("\(gameCol)/\(gameID)/CP").getDocuments() { (querySnapshot, error) in
//            if let error = error{
//                print(error)
//            } else {
//                //print("CP server collection path valid")
//                //this loop is to check for new players and update existing ones
//                //it first updates playerDict, then updates myTeam and otherTeam dicts
//                for document in querySnapshot!.documents {
//                    var cpExist : Bool = false
//                    for cp in self.cps {
//                        if cp.getID() == document.documentID{
//                            cpExist = true
//                        }
//                    }
//                    if(!cpExist){
//                        let newCP = ControlPoint()
//                        let data = document.data()
//                        newCP.setNumRed(numRed: data["numRed"] as? Int ?? 0)
//                        newCP.setNumBlue(numBlue: data["numBlue"] as? Int ?? 0)
//                        newCP.setID(id: document.documentID)
//                        newCP.setCoordinate(coordinate: CLLocationCoordinate2D(latitude: data["lat"] as? Double ?? 0, longitude: data["long"] as? Double ?? 0))
//                        newCP.setTeam(team: data["team"] as? String ?? "")
//                        newCP.setName(name: document.documentID)
//                        newCP.setRadius(radius: data["radius"] as? Double ?? 0)
//
//                        //retrieve points for each team
//                        db.collection("\(gameCol)/\(gameID)/Points").getDocuments() { (querySnapshot, error) in
//                            if let error = error{
//                                print(error)
//                            } else {
//                                for document in querySnapshot!.documents {
//                                    if document.documentID == "Red"{
//                                        newCP.setRedPoints(point: document.data()["points"] as! Double)
//                                    } else{
//                                        newCP.setBluePoints(point: document.data()["points"] as! Double)
//                                    }
//                                }
//                            }
//                        }
//
//                        self.cps.append(newCP)
//
//                        //put CP on map
//                        newCP.title = newCP.getName()
//
//
//                        //print("New CP added: " + newCP.getID())
//                        //print("new CP location: " + String(newCP.getLocation().latitude))
//                    }
//                }
//            }
// */
//        }
//    }
//
//    func existsInDict(annTitleToCheck: String) -> Bool {
//        for thisName in playerDict.keys {
//            if let thisPlayer = playerDict[thisName] {
//                if (thisPlayer.title == annTitleToCheck) {
//                    return true
//                }
//
//                if let thisWard = thisPlayer.getWard() {
//                    if (thisWard.title == annTitleToCheck) {
//                        return true
//                    }
//                }
//            }
//        }
//
//        return false
//    }
//
//    func hasVisionOf(playerToCheck: Player) -> Bool {
//        //if you're the spectator return true
//        if (isSpec) {
//            return true
//        }
//
//        //if they're on your team you can see them
//        if (playerToCheck.getTeam() == myPlayer.getTeam()) {
//            return true
//        }
//
//        let coordToCheck = playerToCheck.getCoordinate()
//        let lat2 : Double = coordToCheck.latitude
//        let lon2 : Double = coordToCheck.longitude
//
//        //loops through every player on your team and checks if that teammate or their ward can see the playerToCheck
//        for thisName in playerDict.keys {
//            if let thisPlayer = playerDict[thisName] {
//                if (!thisPlayer.getConnected() || thisPlayer.getTeam() != myPlayer.getTeam()) {
//                    continue
//                }
//
//                let coord = thisPlayer.getCoordinate()
//                let lat1 = coord.latitude
//                let lon1 = coord.longitude
//
//                if (!thisPlayer.getDead() && latLongDist(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2) < thisPlayer.visionDist) {
//                    //return true
//                }
//
//                if let ward = thisPlayer.getWard() {
//                    let wardCoord = ward.getCoordinate()
//
//                    let lat1 = wardCoord.latitude
//                    let lon1 = wardCoord.longitude
//
//                    if (latLongDist(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2) < wardVisionDist) {
//                        return true
//                    }
//                }
//            }
//        }
//
//        return false
//    }
//
//    func inRespawnArea() -> Bool {
//        for point in respawnPoints {
//            let myCoord = myPlayer.getCoordinate()
//            let pointCoord = point.getCoordinate()
//            let lat1 = myCoord.latitude
//            let lon1 = myCoord.longitude
//            let lat2 = pointCoord.latitude
//            let lon2 = pointCoord.longitude
//
//            if (latLongDist(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2) < respawnDist) {
//                return true
//            }
//        }
//
//        return false
//    }
//
//    //a new borderOverlay has to be created everytime because you can't add new points to an mkpolygon. also, the boords have to be sent individually because if they were all sent as once as a list of coordinates after "boords" we don't know how much to increment when receiving "boords". even if we have a length value right after boords like "boords:5:[coordinates]", it would crash if there is no integer right after boords
//    func addBoord(boord: CLLocation) {
//        map.removeOverlay(border)
//        boords.append(boord)
//        border = BorderOverlay(vertices: boords)
//        map.addOverlay(border)
//    }
//
////    func addRP(name: String, coordinate: CLLocationCoordinate2D) {
////        let point = RespawnPoint(name: name, coordinate: coordinate)
////        respawnPoints.append(point)
////        map.addAnnotation(point)
////    }
////
////    func updatePlayerTeam(name: String, team: String) {
////        if let thisPlayer = playerDict[name] {
////            let oldTeam = thisPlayer.getTeam()
////            thisPlayer.setTeam(team: team)
////
////            if let thisWard = thisPlayer.getWard() {
////                thisWard.setTeam(team: team)
////
////                //the old ward circle needs to be removed here because mapView is only called on adding
////                if let thisOverlay = thisWard.getOverlay() {
////                    map.removeOverlay(thisOverlay)
////                }
////            }
////
////            //have to remove annotation after setting team so the mapView function has the correct info
////            if (team != oldTeam) {
////                map.removeAnnotation(thisPlayer)
////            }
////        }
////    }
////
////    func updatePlayerLoc(name: String, lat: Double, long: Double) {
////        if let thisPlayer = playerDict[name] {
////            if (thisPlayer.getConnected()) {
////                thisPlayer.setCoordinate(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long))
////            }
////        }
////    }
////
////    func updatePlayerDead(name: String, dead: Bool) {
////        if let thisPlayer = playerDict[name] {
////            thisPlayer.setDead(dead: dead)
////        }
////    }
////
////    func updatePlayerWardLoc(name: String, lat: Double, long: Double) {
////        print("updatePlayerWardLoc called")
////
////        if let thisPlayer = playerDict[name] {
////            //this annotation needs to be removed here so that a new ward circle is drawn
////            if let thisWard = thisPlayer.getWard() {
////                map.removeAnnotation(thisWard)
////
////                //the old ward circle needs to be removed here because mapView is only called on adding
////                if let thisOverlay = thisWard.getOverlay() {
////                    map.removeOverlay(thisOverlay)
////                }
////            }
////
////            thisPlayer.addWardAt(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long))
////        }
////    }
////
////    func updatePlayerConn(name: String, conn: Bool) {
////        if let thisPlayer = playerDict[name] {
////            if (!conn) {
////                thisPlayer.setConnected(connected: conn)
////
////                if let thisWard = thisPlayer.getWard() {
////                    //the old ward circle needs to be removed here because mapView is only called on adding
////                    if let thisOverlay = thisWard.getOverlay() {
////                        map.removeOverlay(thisOverlay)
////                    }
////                }
////            }
////        }
////
////        if (conn) {
////            //creating a new player whenever conn is true is fine because in the server i will only send conn as true if it's part of a "new player package". if conn is sent by itself it is always false (i think)
////            ///wrong arguments below
////            //maybe a new player should be created regardless of what conn is, just whenever a conn update is attempted. this is wrong because if conn is false you need to preserve the old player to know that conn is false cuz a new player has a default conn of true
////            //maybe a new player should only be created if conn is changed, either from false to true or true to false. this is wrong because a new player of the same name could've connected within a second of an old one disconnecting, resulting in the server only sending conn true for this player name. in this case, conn stays at true but a new player needs to be created
////            let newPlayer = Player(name: name, team: "none", coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
////            playerDict[name] = newPlayer
////        }
////    }
////
////    //a function i stole online that tells you the distance in meters between two coordinates
////    func latLongDist(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
////        let R = 6378.137 // Radius of earth in KM
////        let dLat = lat2 * Double.pi / 180 - lat1 * Double.pi / 180
////        let dLon = lon2 * Double.pi / 180 - lon1 * Double.pi / 180
////        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1 * Double.pi / 180) * cos(lat2 * Double.pi / 180) * sin(dLon/2) * sin(dLon/2)
////        let c = 2 * atan2(sqrt(a), sqrt(1-a))
////        let d = R * c
////        return d * 1000 // meters
////    }
////
////    override func didReceiveMemoryWarning() {
////        super.didReceiveMemoryWarning()
////    }
////
////}
//
//
//func addRP(name: String, coordinate: CLLocationCoordinate2D) {
//    let point = RespawnPoint(name: name, coordinate: coordinate)
//    respawnPoints.append(point)
//}
//}
