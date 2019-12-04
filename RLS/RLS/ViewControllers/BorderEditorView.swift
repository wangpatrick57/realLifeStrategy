//
//  HostGameIDView.swift
//
//
//  Created by Melody Lee on 8/1/18.
//
import Foundation
import UIKit
import MapKit

class BorderEditorView : UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    let manager = CLLocationManager()
    var once = false
    var border: BorderOverlay = BorderOverlay()
    let mapViewDelegate = MapViewDelegate()
    var myBorderPoints = createdBorderPoints
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //map stuff
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        mapView.delegate = mapViewDelegate
        
        //draw game elements
        redrawBorder(bp: myBorderPoints)
        
        for rp in createdRespawnPoints {
            mapView.addAnnotation(rp)
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
        addBorderPoint(bp: BorderPoint(coordinate: touchCoord))
    }
    
    func addBorderPoint(bp: BorderPoint) {
        myBorderPoints.append(bp)
        redrawBorder(bp: myBorderPoints)
    }
    
    func redrawBorder(bp: [BorderPoint]) {
        mapView.removeOverlay(border)
        border = BorderOverlay(bp: bp)
        mapView.addOverlay(border)
    }
    
    @IBAction func savePressed(_ sender: Any) {
        //stop the location manager
        manager.stopUpdatingLocation()
        
        //save
        createdBorderPoints = myBorderPoints
        
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
        myBorderPoints = Array(myBorderPoints[0..<(myBorderPoints.count - 1)])
        redrawBorder(bp: myBorderPoints)
    }
    
    @IBAction func trashPressed(_ sender: Any) {
        myBorderPoints = []
        redrawBorder(bp: myBorderPoints)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //var DestViewController : NicknameTFView = segue.destination as! NicknameTFView
    }
}
