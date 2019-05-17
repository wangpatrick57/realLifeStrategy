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
    private var team : UIColor
    private var location : CLLocationCoordinate2D
    private var id : String
    
    override init(){
        self.numRed = 0
        self.numBlue = 0
        self.team = UIColor.gray
        self.location = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        self.id = ""
        super.init()
        determineColor()
        
        //write CP data to Firebase
//        db.document("Games/" + gameID + "/ControlPoints/" + ("CP" + self.location.latitude)).updateData(["lat": location.latitude, "long": location.longitude, "color": color, "numRed": numRed, "numBlue": numBlue,])
    }
    
    func setNumRed(numRed : Int) {
        self.numRed = numRed
    }
    
    func setNumBlue(numBlue : Int) {
        self.numBlue = numBlue
    }
    
    //automatically calls determineColor() to update the color of the CP
    func getTeam() -> UIColor {
        determineColor()
        return team
    }
    
    func setLocation(location : CLLocationCoordinate2D) {
        self.location = location
    }
    
    func getID() -> String {
        return id
    }
    
    func setID(id : String){
        self.id = id
    }
    
    //determines the color of the CP depends on the amount of players on each team in the territory
    func determineColor(){
        if numBlue == numRed {
            team = UIColor.gray
        } else if numBlue > numRed {
            team = UIColor.blue
        } else {
            team = UIColor.red
        }
        
    }
}
