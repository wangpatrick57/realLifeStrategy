//
//  RespawnEditorView.swift
//  RLS
//
//  Created by Patrick Wang on 10/9/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class RespawnPointEditorView : UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    let manager = CLLocationManager()
    var once = false
    var border: BorderOverlay = BorderOverlay()
    let mapViewDelegate = MapViewDelegate()
    var myRespawnPoints = createdRespawnPoints
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //map stuff
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        mapView.delegate = mapViewDelegate
        
        //draw game elements
        redrawBorder(bp: createdBorderPoints)
        
        for rp in myRespawnPoints {
            addRespawnPoint(rp: rp)
        }
        
        //tap recognizer
        let tgr = UITapGestureRecognizer(target: self, action: #selector(handleTap(gestureRecognizer:)))
        tgr.delegate = self
        mapView.addGestureRecognizer(tgr)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0] //the latest location
        
        if (!once){
            let span: MKCoordinateSpan = MKCoordinateSpan.init(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let myLocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
            let region:MKCoordinateRegion = MKCoordinateRegion.init(center: myLocation, span: span)
            mapView.setRegion(region, animated: true)
            self.mapView.showsUserLocation = true
            once = true
        }
    }
    
    @objc func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        let touchLocation = gestureRecognizer.location(in: mapView)
        let touchCoord = mapView.convert(touchLocation,toCoordinateFrom: mapView)
        let newRP = RespawnPoint(index: myRespawnPoints.count, coordinate: touchCoord)
        addRespawnPoint(rp: newRP)
    }
    
    @IBAction func savePressed(_ sender: Any) {
        //set the global respawn point array to the local one
        createdRespawnPoints = myRespawnPoints
        
        //stop the location manager
        manager.stopUpdatingLocation()
        
        //go to nickname view
        self.performSegue(withIdentifier: "ShowCustomizeGame", sender: self)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        //don't save (don't do anything)
        
        //stop the location manager
        manager.stopUpdatingLocation()
        
        //go to nickname view
        self.performSegue(withIdentifier: "ShowCustomizeGame", sender: self)
    }
    
    @IBAction func undoPressed(_ sender: Any) {
        removeRespawnPoint(rp: myRespawnPoints[myRespawnPoints.count - 1])
    }
    
    @IBAction func trashPressed(_ sender: Any) {
        for rp in myRespawnPoints {
            removeRespawnPoint(rp: rp)
        }
    }
    
    func redrawBorder(bp: [BorderPoint]) {
        mapView.removeOverlay(border)
        border = BorderOverlay(bp: bp)
        mapView.addOverlay(border)
    }
    
    func addRespawnPoint(rp: RespawnPoint) {
        myRespawnPoints.append(rp)
        mapView.addAnnotation(rp)
    }
    
    func removeRespawnPoint(rp: RespawnPoint) {
        if let index = myRespawnPoints.index(of: rp) {
            myRespawnPoints.remove(at: index)
        }
        
        mapView.removeAnnotation(rp)
        
        if let overlay = rp.getOverlay() {
            mapView.removeOverlay(overlay)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //var DestViewController : NicknameTFView = segue.destination as! NicknameTFView
    }
}
