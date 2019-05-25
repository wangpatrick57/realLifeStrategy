//
//  ControlPoint.swift
//  RLS
//
//  Created by Melody Lee on 5/14/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//
//  Properties of a control point
//  Control point changes colors depending on the amount of players of each team in a certain radius.

import Foundation
import MapKit
import Firebase
import CoreLocation

class ControlPoint : MKPointAnnotation{
    private var numRed : Int
    private var numBlue : Int
    private var team : String
    private var id : String
    private var radius : Double
    private var playerStay : Bool //checks if player is staying in CP radius or just entered; true being player is staying in CP
    private var redPoints : Double
    private var bluePoints : Double
    
    override init(){
        self.numRed = 0
        self.numBlue = 0
        self.team = "neutral"
        self.id = ""
        self.radius = 10000
        self.playerStay = false
        self.redPoints = 0
        self.bluePoints = 0
        super.init()
        self.title = self.id
        
        //write CP data to Firebase
//        db.document("\(gameCol)/\(gameID)/ControlPoints/" + ("CP" + self.location.latitude)).updateData(["lat": location.latitude, "long": location.longitude, "color": color, "numRed": numRed, "numBlue": numBlue,])
    }
    
    func setNumRed(numRed : Int) {
        self.numRed = numRed
    }
    
    func getNumRed() -> Int {
        return numRed
    }
    
    func setNumBlue(numBlue : Int) {
        self.numBlue = numBlue
    }
    
    func getNumBlue() -> Int {
        return numBlue
    }
    
    //automatically calls determineColor() to update the color of the CP
    func getTeam() -> String {
        determineColor()
        return team
    }
    
    func setTeam(team : String){
        self.team = team
    }
    
    func setCoordinate(coordinate: CLLocationCoordinate2D) -> Void {
        self.coordinate = coordinate
    }
    
    func getLocation() -> CLLocationCoordinate2D{
        return coordinate
    }
    
    func getID() -> String {
        return id
    }
    
    func setID(id : String){
        self.id = id
        self.title = self.id
    }
    
    func setRadius(radius : Double){
        self.radius = radius
    }
    
    func setRedPoints(point : Double){
        redPoints = point
    }
    
    func setBluePoints(point : Double){
        bluePoints = point
    }
    
    //adds points and returns the updated number of points
    func incrementRedPoints(pt : Double) -> Double{
        redPoints = redPoints + pt
        return redPoints
    }
    
    func incrementBluePoints(pt : Double) -> Double{
        bluePoints = bluePoints + pt
        return bluePoints
    }
    
    //determines the color of the CP depends on the amount of players on each team in the territory
    func determineColor(){
        if numBlue == numRed{
            return
        }else if numBlue > numRed {
            team = "blue"
        } else {
            team = "red"
        }
        
    }
    
    //to increase the number of red players in the radius of CP
    func addNumRed(num : Int){
        numRed = numRed + num
    }
    
    //to increase the number of blue players in the radius of CP
    func addNumBlue(num : Int){
        numBlue = numBlue + num
    }
    
    //determines if player is in the radius of CP
    func inArea(myPlayer : Player) -> Bool {
        let myCoord = myPlayer.getCoordinate()
        let lat1 = myCoord.latitude
        let lon1 = myCoord.longitude
        let lat2 = coordinate.latitude
        let lon2 = coordinate.longitude
        
        if (latLongDist(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2) < radius && myPlayer.getConnected() && !myPlayer.getDead()) {
            if playerStay {
                return false
            }
            //print("player has entered the CP radius")
            playerStay = true
            return true
        }
        
        //print("player has left CP radius")
        playerStay = false
        return false
    }
    
    private func latLongDist(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6378.137 // Radius of earth in KM
        let dLat = lat2 * Double.pi / 180 - lat1 * Double.pi / 180
        let dLon = lon2 * Double.pi / 180 - lon1 * Double.pi / 180
        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1 * Double.pi / 180) * cos(lat2 * Double.pi / 180) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        let d = R * c
        return d * 1000 // meters
    }
    
//   public override var description: String{
//        return "\nControl Point at ["
//            + location.latitude
//            + ", " + location.longitude
//            + "] .Color: " + team
//            + ".\n"
//    }
}
