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
    var respawnPoints: [RespawnPoint] = []
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
    var respawnTime = 15.0 //seconds
    let respawnDist = 20.0 //meters
    let cpDist = 50.0 //meters
    let wardVisionDist = 30.0 //meters
    @IBOutlet weak var gameIDLabel: UILabel!
    var cps = [ControlPoint]() //collection of control points - date retrieve from server
    var isSpec = false
    
    var font : String = "San Francisco"
    
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
        
        //check if spectator
        if (myPlayer.getName() == ".SPECTATOR") {
            isSpec = true
        }
        
        //retrieve data of control point from server
        getCPData()
        
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
            respawnTime = 1.0
        }
        
        //Change button colors to Player's team color
        if myPlayer.getTeam() == "red" {
            returnButtonMap.setTitleColor(.red, for : .normal)
            ward.setTitleColor(.red, for : .normal)
            death.setTitleColor(.red, for : .normal)
        } else if myPlayer.getTeam() == "blue"{
            returnButtonMap.setTitleColor(.blue, for : .normal)
            ward.setTitleColor(.blue, for : .normal)
            death.setTitleColor(.blue, for : .normal)
        } else{ //a spectator
            returnButtonMap.setTitleColor(.gray, for : .normal)
            ward.setTitleColor(.gray, for : .normal)
            death.setTitleColor(.gray, for : .normal)
        }
        
        //add myPlayer to playerDict
        playerDict[myPlayer.getName()] = myPlayer
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
                myPlayer.setCoordinate(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
            }
            
            once = true
        }
        
        //write data
        //set coordinates and death status
        if (!isSpec) {
            myPlayer.setCoordinate(coordinate: location.coordinate)
        }
        
        db.document("\(gameCol)/\(gameID)/Players/\(myPlayer.getName())").updateData([
            "lat": myPlayer.getCoordinate().latitude,
            "long": myPlayer.getCoordinate().longitude,
            ])
    }
    
    @IBAction func onReturnPressed(_ sender: Any) {
        if (!debug) {
            db.document("\(gameCol)/\(gameID)/Players/\(myPlayer.getName())").delete() { err in
                print(err)
            }
        }
        
        self.performSegue(withIdentifier: "ShowPlayerList", sender: nil)
    }
    
    @IBAction func dropWard(_ sender: Any) {
        if (!myPlayer.getDead()) {
            myPlayer.addWard()
            let coordinate = myPlayer.getCoordinate()
            
            db.document("\(gameCol)/\(gameID)/Players/\(myPlayer.getName())").updateData([
                "wardLat": coordinate.latitude,
                "wardLong": coordinate.longitude
                ])
        }
    }
    
    @IBAction func death(_ sender: Any) {
        if (debug) {
            myPlayer.setDead(dead: !myPlayer.getDead())
                
            db.document("\(gameCol)/\(gameID)/Players/\(myPlayer.getName())").updateData([
                "dead": myPlayer.getDead()
                ])
        } else {
            myPlayer.setDead(dead: true)
            
            db.document("\(gameCol)/\(gameID)/Players/\(myPlayer.getName())").updateData([
                "dead": myPlayer.getDead()
                ])
        }
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
            
            /*db.document("\(gameCol)/\(gameID)/Pings/\(pingName)").updateData([
                "lat": locationCoordinate.latitude,
                "long": locationCoordinate.longitude,
                "team": myPlayer.getTeam()
                ])*/
        }
    }
    
    @objc func handleData() {
        getData()
        //sendData()
    }
    
    //i'm using getData() basically like the update function in unity
    func getData() {
        //eventually make a server app that calculates vision so that the clients don't have access to all the enemies' positions
        
        //get player data
        db.collection("\(gameCol)/\(gameID)/Players/").getDocuments() { (querySnapshot, error) in
            if let error = error{
                print(error)
            } else {
                //set all players as disconnected
                for thisName in self.playerDict.keys {
                    if let thisPlayer = self.playerDict[thisName] {
                        if (thisPlayer != myPlayer) {
                            thisPlayer.setConnected(connected: false)
                        }
                    }
                }
                
                //loop to add all the players
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
                            let playerToAdd = Player(name: thisName, team: data["team"] as? String ?? "none", coordinate: thisCoordinate, dead: thisDead)
                            
                            if (thisWardCoordinate.latitude != 0 || thisWardCoordinate.longitude != 0) {
                                playerToAdd.addWardAt(coordinate: thisWardCoordinate)
                            }
                            
                            self.playerDict[thisName] = playerToAdd
                        }
                        
                        self.playerDict[thisName]?.setConnected(connected: true)
                    }
                }
                
                //step is in here so it runs AFTER getting all the data
                self.step()
            }
        }
    }
    
    func step() {
        //RESPAWN
        let currTime = CACurrentMediaTime()
        
        if (myPlayer.getDead()) {
            if (inRespawnArea()) {
                if (currTime > respawnEnterTime + respawnTime) {
                    myPlayer.setDead(dead: false)
                    
                    db.document("\(gameCol)/\(gameID)/Players/\(myPlayer.getName())").updateData([
                        "dead": myPlayer.getDead()
                        ])
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
                let thisConnected = thisPlayer.getConnected()
                
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
                
                if (thisConnected && !playerOnMap && !thisDead) {
                    map.addAnnotation(thisPlayer)
                }
                
                if (playerOnMap && (thisDead || !thisConnected)) {
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
                let thisConnected = thisPlayer.getConnected()
                let visible = self.hasVisionOf(playerToCheck: thisPlayer)
                
                for ann in annArray {
                    if (thisPlayer.title == ann.title) {
                        playerOnMap = true
                    }
                }
                
                if (thisConnected && !playerOnMap && (!thisDead && visible)) {
                    map.addAnnotation(thisPlayer)
                }
                
                if (playerOnMap && (thisDead || !visible || !thisConnected)) {
                    map.removeAnnotation(thisPlayer)
                }
            }
        }
        
        //DRAW MKMAPOVERLAYS
        //draw rays based on a dict
        //draw circles around each player and ward in myTeamDict for vision OR just wards if we're doing that
        
        //Check if player is in the CP radius
        for cp in self.cps{
            if cp.inArea(myPlayer: myPlayer) {
                let cpRef : DocumentReference = db.document("\(gameCol)/\(gameID)/CP/\(cp.getID())")
                //if player is in radius, update number in server
                if myPlayer.getTeam() == "red"{
                    cp.addNumRed(num: 1)
                    cpRef.updateData(["numRed": cp.getNumRed()])
                    //print("updated numRed in server")
                } else if myPlayer.getTeam() == "red"{
                    cp.addNumBlue(num: 1)
                    cpRef.updateData(["numBlue": cp.getNumBlue()])
                    //print("updated numBlue in server")
                }
                cpRef.updateData(["team" : cp.getTeam()])
            }
            
            //add points to team: 1 point per second to the team cp belongs to
            let pointsRedRef : DocumentReference = db.document("\(gameCol)/\(gameID)/Points/Red/")
            let pointsBlueRef : DocumentReference = db.document("\(gameCol)/\(gameID)/Points/Blue/")
            if cp.getTeam() == "red" {
                pointsRedRef.updateData(["points" : cp.incrementRedPoints(pt: 1)])
            } else if cp.getTeam() == "blue" {
                pointsBlueRef.updateData(["points" : cp.incrementBluePoints(pt: 1)])
            } else {
                pointsRedRef.updateData(["points" : cp.incrementRedPoints(pt: 0.5)])
                pointsBlueRef.updateData(["points" : cp.incrementBluePoints(pt: 0.5)])
            }
        }
        
    }
    
    //retrieve control point from server
    func getCPData(){
        //print("getting CP data from server")
        
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
                        self.map.addAnnotation(newCP)
                        
                        //print("New CP added: " + newCP.getID())
                        //print("new CP location: " + String(newCP.getLocation().latitude))
                    }
                }
            }
        }
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
                if (thisPlayer.getTeam() != myPlayer.getTeam()) {
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
    
    //called when an annotation is added or deleted I think?
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annName: String = "you"
        var annTeam: String = "none"
        
        if let annotation = annotation as? Player {
            annName = annotation.getName()
            annTeam = annotation.getTeam()
        }
        
        if let annotation = annotation as? Ward {
            annName = annotation.getName()
            annTeam = annotation.getTeam()
        }
        
        if let annotation = annotation as? ControlPoint {
            annName = ""
            annTeam = annotation.getTeam()
        }
        
        if let annotation = annotation as? RespawnPoint {
            annName = annotation.getName()
        }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annName)
        
        if annotationView == nil{
            annotationView = MKAnnotationView.init(annotation: annotation, reuseIdentifier: annName)
        }
        
        if let annotation = annotation as? Player{
            if annotation.getTeam() == "red" {
                annotationView?.image = UIImage(named: "Red Player")
                //annotation.title = annotation.getName()
                
                if #available(iOS 11.0, *) {
                    annotationView?.displayPriority = .required
                } else {
                    // Fallback on earlier versions
                }
            }
            
            if annotation.getTeam() == "blue" {
                annotationView?.image = UIImage(named: "Blue Player")
                //annotation.title = annotation.getName()
                
                if #available(iOS 11.0, *) {
                    annotationView?.displayPriority = .required
                } else {
                    //do nothing
                }
            }
            
            if annotation.getTeam() == "neutral" {
                annotationView?.image = UIImage(named: "")
                //annotation.title = annotation.getName()
                
                if #available(iOS 11.0, *) {
                    annotationView?.displayPriority = .required
                } else {
                    //do nothing
                }
            }
        }
        
        if let annotation = annotation as? Ward{
            let circle = ColorCircleOverlay(annotation: annotation, radius: wardVisionDist, color: UIColor.black)
            if annotation.getTeam() == "red" {
                annotationView?.image = UIImage(named: "Red Ward")
                circle.color = UIColor.red
                if #available(iOS 11.0, *) {
                    annotationView?.displayPriority = .required
                } else {
                    //do nothing
                }
            }
            if annotation.getTeam() == "blue" {
                annotationView?.image = UIImage(named: "Blue Ward")
                circle.color = UIColor.blue
                if #available(iOS 11.0, *) {
                    annotationView?.displayPriority = .required
                } else {
                    //do nothing
                }
            }
            mapView.addOverlay(circle)
        }
        
        if let annotation = annotation as? ControlPoint{
            let circle = ColorCircleOverlay(annotation: annotation, radius: cpDist, color: UIColor.black)
            
            if annotation.getTeam() == "neutral" {
                annotationView?.image = UIImage(named: "Gray CP")
            }
            if annotation.getTeam() == "red" {
                circle.color = UIColor.red
                annotationView?.image = UIImage(named: "Red CP") //Need to make icons for control points
            }
            if annotation.getTeam() == "blue" {
                circle.color = UIColor.blue
                annotationView?.image = UIImage(named: "Blue CP")
            }
            
            mapView.addOverlay(circle)
        }
        
        if let annotation = annotation as? RespawnPoint {
            let circle = ColorCircleOverlay(annotation: annotation, radius: respawnDist, color: UIColor.black)
            
            annotationView?.image = UIImage(named: "Respawn Point")
            //annotation.title = annotation.getName()
            
            if #available(iOS 11.0, *) {
                annotationView?.displayPriority = .required
            } else {
                // Fallback on earlier versions
            }
            
            mapView.addOverlay(circle)
        }
        
        //add title
        if annotationView?.subviews.isEmpty ?? false{
            let name = UILabel(frame: CGRect(x: -19, y: 18, width: 50, height: 12))
            name.textAlignment = .center
            name.font = UIFont(name: font, size: 12)
            name.text = annName
            name.backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 0.8, alpha: 0.5)
            name.adjustsFontSizeToFitWidth = true
            name.minimumScaleFactor = 0.5
            annotationView?.addSubview(name)
        }
        annotationView?.canShowCallout = true
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? ColorCircleOverlay{
            let render = MKCircleRenderer(circle: overlay)
            render.strokeColor = overlay.color
            render.lineWidth = 2
            return render
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
    
}
