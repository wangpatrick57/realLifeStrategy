//
//  Ward.swift
//  RLS
//
//  Created by Patrick Wang on 5/4/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class Ward: MKPointAnnotation{
    private var name: String
    private var team: String
    private var locChanged: Bool
    private var circleOverlay: ColorCircleOverlay?
    let math = SpecMath()
    
    init(name:String,team:String,coordinate:CLLocationCoordinate2D){
        self.name=name
        self.team=team
        self.locChanged = false
        super.init()
        self.title = self.name
        let truncatedCoord = CLLocationCoordinate2D(latitude: math.truncate(num: coordinate.latitude), longitude: math.truncate(num: coordinate.longitude))
        self.coordinate = truncatedCoord
    }
    
    func setCoordinate(coordinate: CLLocationCoordinate2D) -> Void {
        //extra code here to check if location is being changed
        if (coordinate.latitude != self.coordinate.latitude || coordinate.longitude != self.coordinate.longitude) {
            locChanged = true
        }
        
        let truncatedCoord = CLLocationCoordinate2D(latitude: math.truncate(num: coordinate.latitude), longitude: math.truncate(num: coordinate.longitude))
        self.coordinate = truncatedCoord
    }
    
    func getCoordinate()->CLLocationCoordinate2D {
        return self.coordinate
    }
    
    func getName() -> String {
        return name
    }
    
    func setTeam(team: String) {
        self.team = team
    }
    
    func getTeam() -> String {
        return team
    }
    
    func getLocChanged() -> Bool {
        return locChanged
    }
    
    func setLocChanged(locChanged: Bool) {
        self.locChanged = locChanged
    }
    
    func getOverlay() -> ColorCircleOverlay? {
        return circleOverlay
    }
    
    func setOverlay(circleOverlay: ColorCircleOverlay) {
        self.circleOverlay = circleOverlay
    }
}
