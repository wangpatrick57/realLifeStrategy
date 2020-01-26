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

var mapViewController: MapViewController!

class MapViewController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    
    //ib outlets
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var ward : UIButton!
    @IBOutlet weak var quitButtonMap: UIButton!
    @IBOutlet weak var death : UIButton!
    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var redPtLabel: UILabel!
    @IBOutlet weak var bluePtLabel: UILabel!
    
    //other vars
    let manager = CLLocationManager()
    var playerDict: [String: Player] = [myPlayer.getName() : myPlayer] //dictionary of all players
    var shadowDict: [String: Player] = [:] //dictionary of all shadows
    var deadNames: [String] = [] //list of the names of the dead players on "my" team
    var myPings: [String: Double] = [:] //dict of the names of my pings to their create times. the name is "\(myName)\(pingNum)"
    var border: BorderOverlay = BorderOverlay()
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
    let startDate = Date()
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
        manager.distanceFilter = CLLocationDistance(5.0)
        mapViewController = self
        map.delegate = mapViewDelegate
        
        //other necessary stuff
        inGame = true
        networking.clearSendRecBP()
        networking.clearSendRecRP()
        networking.setSendOneTimer(key: BP_CT, value: true)
        networking.setSendOneTimer(key: RP_CT, value: true)
        
        //check if spectator
        if (myPlayer.getName() == ".SPECTATOR") {
            isSpec = true
        }
        
        //retrieve data of control point from server
        getCPData()
        
        //start step function timer
        stepTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(step), userInfo: nil, repeats: true)
        
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
        
        if (debug) {
            respawnTime = 5.0
        }
        
        //Change button colors to Player's team color
        if myPlayer.getTeam() == "red" {
            quitButtonMap.setTitleColor(.red, for : .normal)
            ward.setTitleColor(.red, for : .normal)
            death.setTitleColor(.red, for : .normal)
        } else if myPlayer.getTeam() == "blue" {
            quitButtonMap.setTitleColor(.blue, for : .normal)
            ward.setTitleColor(.blue, for : .normal)
            death.setTitleColor(.blue, for : .normal)
        } else { //a spectator
            quitButtonMap.setTitleColor(.gray, for : .normal)
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
            
            if (isSpec) {
                setPlayerCoordinate(player: myPlayer, coordinate: CLLocationCoordinate2D(latitude: 200, longitude: 200))
                networking.sendLocation(coord: myPlayer.getCoordinate())
            }
            
            once = true
        }
        
        //write data
        //set coordinates and death status
        if (!isSpec) {
            setPlayerCoordinate(player: myPlayer, coordinate: location.coordinate)
            networking.sendLocation(coord: myPlayer.getCoordinate())
        }
    }
    
    @IBAction func onQuitPressed(_ sender: Any) {
        if (true/*!debug*/) {
            //tell server
            myPlayer.setConnected(connected: false)
            networking.setSendOneTimer(key: DC, value: true)
        }
        
        //stopping/setting to nil all the globalvars
        manager.stopUpdatingLocation()
        stepTimer.invalidate()
        mapViewController = nil //this must be set to nil here so that when the client receives team or dead info from other players after the checkName screen (since after the client checks name the server creates a player object with connected = true, so it starts sending info to that player), the client won't send back teamCk or deadCk. if the client did send back teamCk or deadCk, the server would stop sending team and dead info when the client can actually use it (when you're in the map screen)
        inGame = false
        borderPoints = []
        respawnPoints = []
        self.performSegue(withIdentifier: "ShowHostOrJoin", sender: nil)
    }
    
    @IBAction func dropWard(_ sender: Any) {
        if (!myPlayer.getDead()) {
            let coordinate = myPlayer.getCoordinate()
            
            if let myWard = myPlayer.getWard() {
                map.removeAnnotation(myWard)
            }
            
            myPlayer.addWardAt(coordinate: coordinate)
            networking.setSendOneTimer(key: WARD, value: true)
        }
    }
    
    @IBAction func death(_ sender: Any) {
        if (debug) {
            myPlayer.setDead(dead: !myPlayer.getDead())
        } else {
            myPlayer.setDead(dead: true)
        }
        
        map.removeAnnotation(myPlayer)
        networking.setSendOneTimer(key: DEAD, value: true)
    }
    
    //ping with long press
    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchLocation = gestureRecognizer.location(in: map)
            //let locationCoordinate = map.convert(touchLocation,toCoordinateFrom: map)
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
        
        //RESPAWN
        let currTime = CACurrentMediaTime()
        
        if (myPlayer.getDead()) {
            if (inRespawnArea()) {
                if (currTime > respawnEnterTime + respawnTime) {
                    myPlayer.setDead(dead: false)
                    networking.setSendOneTimer(key: DEAD, value: true)
                    map.removeAnnotation(myPlayer)
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
                    targetAnnDict[thisName] = thisPlayer
                    
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
                    targetAnnDict[thisName] = thisPlayer
                }
                
                if (isSpec) {
                    if let thisWard = thisPlayer.getWard() {
                        targetAnnDict[thisWard.getName()] = thisWard
                    }
                }
            }
        }
        
        //shadows
        for thisName in shadowDict.keys {
            if let thisPlayer = shadowDict[thisName] {
                if (thisPlayer.getTeam() == myPlayer.getTeam()) {
                    targetAnnDict[thisName] = thisPlayer
                } else {
                    if (hasVisionOf(playerToCheck: thisPlayer)) {
                        targetAnnDict[thisName] = thisPlayer
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
    }
    
    //retrieve control point from server
    func getCPData(){
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
    
    func setPlayerCoordinate(player: Player, coordinate: CLLocationCoordinate2D) {
        player.setCoordinate(coordinate: coordinate)
        
        // add shadow player
        if (enableShadows && Date().timeIntervalSince(player.getLastShadowDate()) > shadowInterval) {
            // adding the annotation
            let shadowPlayer = Player(name: "\(player.getName()): \(Int(round(Date().timeIntervalSince(startDate))))")
            shadowPlayer.setTeam(team: player.getTeam())
            shadowPlayer.setCoordinate(coordinate: player.getCoordinate())
            shadowPlayer.setDead(dead: true)
            shadowDict[shadowPlayer.getName()] = shadowPlayer
            
            // resetting the player's lastShadowDate
            player.setLastShadowDate(lastShadowDate: Date())
        }
    }
    
    //a new borderOverlay has to be created everytime because you can't add new points to an mkpolygon. also, the borderPoints have to be sent individually because if they were all sent as once as a list of coordinates after "bp" we don't know how much to increment when receiving "bp". even if we have a length value right after bp like "bp:5:[coordinates]", it would crash if there is no integer right after bp
    func addBorderPoint(index: Int, coordinate: CLLocationCoordinate2D) {
        map.removeOverlay(border)
        let borderPoint = BorderPoint(coordinate: coordinate)
        
        while (borderPoints.count <= index) {
            borderPoints.append(borderPoint)
        }
        
        borderPoints[index] = borderPoint
        
        border = BorderOverlay(bp: borderPoints)
        map.addOverlay(border)
    }
    
    func addRespawnPoint(index: Int, coordinate: CLLocationCoordinate2D) {
        let respawnPoint = RespawnPoint(index: index, coordinate: coordinate)
        
        while (respawnPoints.count <= index) {
            respawnPoints.append(respawnPoint)
        }
        
        respawnPoints[index] = respawnPoint
        map.addAnnotation(respawnPoint)
    }
    
    func updatePlayerTeam(name: String, team: String) {
        print("updatePlayerTeam called with name:\(name) and team:\(team)")
        
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
            
            print("player \(name) already exists")
        } else {
            let newPlayer = Player(name: name)
            newPlayer.setTeam(team: team)
            playerDict[name] = newPlayer
            
            print("player \(name) doesn't exist")
        }
    }
    
    func updatePlayerLoc(name: String, lat: Double, long: Double) {
        if let thisPlayer = playerDict[name] {
            setPlayerCoordinate(player: thisPlayer, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long))
        }
    }
    
    func updatePlayerDead(name: String, dead: Bool) {
        if let thisPlayer = playerDict[name] {
            thisPlayer.setDead(dead: dead)
            map.removeAnnotation(thisPlayer)
        } else {
            let newPlayer = Player(name: name)
            newPlayer.setDead(dead: dead)
            playerDict[name] = newPlayer
        }
    }
    
    func updatePlayerWardLoc(name: String, lat: Double, long: Double) {
        if let thisPlayer = playerDict[name] {
            if let thisWard = thisPlayer.getWard() {
                //only do something if the ward pos sent is different
                if (thisWard.getCoordinate().latitude != lat || thisWard.getCoordinate().longitude != long) {
                    //this annotation needs to be removed here so that a new ward circle is drawn
                    map.removeAnnotation(thisWard)
                    
                    //the old ward circle needs to be removed here because mapView is only called on adding
                    if let thisOverlay = thisWard.getOverlay() {
                        map.removeOverlay(thisOverlay)
                    }
                }
            }
            
            thisPlayer.addWardAt(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long))
        } else {
            let newPlayer = Player(name: name)
            newPlayer.addWardAt(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long))
            playerDict[name] = newPlayer
        }
    }
    
    func playerDC(name: String) {
        if let thisPlayer = playerDict[name] {
            if let thisWard = thisPlayer.getWard() {
                map.removeAnnotation(thisWard)
                
                //the old ward circle needs to be removed here because mapView is only called on adding
                if let thisOverlay = thisWard.getOverlay() {
                    map.removeOverlay(thisOverlay)
                }
            }
            
            playerDict[name] = nil
        } else {
            print("player \(name) trying to dc doesn't exit")
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
