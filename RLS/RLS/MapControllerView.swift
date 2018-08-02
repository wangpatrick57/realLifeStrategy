//
//  MapView.swift
//  GameMap
//
//  Created by Melody Lee on 4/22/18.
//  Copyright © 2018 Hackathon Event. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class MapControllerView: UIViewController,CLLocationManagerDelegate {
    
    @IBOutlet weak var map: MKMapView!
    
    let manager=CLLocationManager()
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //send location to firebase
        print("a")
        //self.map.showsUserLocation=true
    }
    
    func initiatePlayers(){
        var latitude:[Double] = [37.6142,37.6242]
        var longitude:[Double] = [-122.3742,-122.3842]
        var team:[String] = ["red","blue"]
        var id:[Double] = [1,2]
        var name:[String] = ["Johnny", "Jerry"]
        
        for i in 0...longitude.count-1 {
            let p=Player(name:name[i],team:team[i],id:id[i],coordinate: CLLocationCoordinate2D(latitude:latitude[i],longitude: longitude[i]))
            map.addAnnotation(p)
            print(p)
        }
    }
    
    let homeLocation = CLLocation(latitude:37.6213 , longitude: -122.3790)
    let regionRadius: CLLocationDistance = 1000
    func centerMapOnLocation(location: CLLocation)
    {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        map.setRegion(coordinateRegion, animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        manager.delegate=self
        //locationManager(manager, didUpdateLocations: )
        manager.desiredAccuracy=kCLLocationAccuracyBest
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
        print("\(manager.location?.coordinate.latitude)")
        print("\(manager.location?.coordinate.longitude)")
        //Zoom to user location
        map.showsUserLocation = true
        centerMapOnLocation(location: homeLocation)
        initiatePlayers()
        
        print("b")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
