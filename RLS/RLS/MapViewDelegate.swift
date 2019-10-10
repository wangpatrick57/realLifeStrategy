//
//  MapViewDelegate.swift
//  RLS
//
//  Created by Patrick Wang on 8/25/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//
import Foundation
import MapKit

class MapViewDelegate: NSObject, MKMapViewDelegate {
    //called when an annotation is added or deleted I think?
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        print("mapView called")
        
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
                if (!annotation.getDead()) {
                    annotationView?.image = UIImage(named: "Red Player")
                } else {
                    annotationView?.image = UIImage(named: "Red Ward")
                }
                
                if #available(iOS 11.0, *) {
                    annotationView?.displayPriority = .required
                } else {
                    // Fallback on earlier versions
                }
            }
            
            if annotation.getTeam() == "blue" {
                if (!annotation.getDead()) {
                    annotationView?.image = UIImage(named: "Blue Player")
                } else {
                    annotationView?.image = UIImage(named: "Blue Ward")
                }
                
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
        
        if let annotation = annotation as? Ward {
            print("\(annotation.getName())")
            
            //delete old overlay if overlay already exists
            if let thisWardOverlay = annotation.getOverlay() {
                mapView.removeOverlay(thisWardOverlay)
            }
            
            let circleOverlay = ColorCircleOverlay(annotation: annotation, radius: wardVisionDist, color: UIColor.black)
            annotation.setOverlay(circleOverlay: circleOverlay)
            
            if annotation.getTeam() == "red" {
                annotationView?.image = UIImage(named: "Red Ward")
                circleOverlay.setColor(color: UIColor.red)
                if #available(iOS 11.0, *) {
                    annotationView?.displayPriority = .required
                } else {
                    //do nothing
                }
            }
            
            if annotation.getTeam() == "blue" {
                annotationView?.image = UIImage(named: "Blue Ward")
                circleOverlay.setColor(color: UIColor.blue)
                if #available(iOS 11.0, *) {
                    annotationView?.displayPriority = .required
                } else {
                    //do nothing
                }
            }
            
            mapView.addOverlay(circleOverlay)
        }
        
        if let annotation = annotation as? ControlPoint{
            let circleOverlay = ColorCircleOverlay(annotation: annotation, radius: cpDist, color: UIColor.black)
            
            if annotation.getTeam() == "neutral" {
                annotationView?.image = UIImage(named: "Gray CP")
            }
            if annotation.getTeam() == "red" {
                circleOverlay.setColor(color: UIColor.red)
                annotationView?.image = UIImage(named: "Red CP")
            }
            if annotation.getTeam() == "blue" {
                circleOverlay.setColor(color: UIColor.blue)
                annotationView?.image = UIImage(named: "Blue CP")
            }
            
            mapView.addOverlay(circleOverlay)
        }
        
        if let annotation = annotation as? RespawnPoint {
            let circleOverlay = ColorCircleOverlay(annotation: annotation, radius: respawnDist, color: UIColor.black)
            annotation.setOverlay(overlay: circleOverlay)
            
            annotationView?.image = UIImage(named: "Respawn Point")
            //annotation.title = annotation.getName()
            
            if #available(iOS 11.0, *) {
                annotationView?.displayPriority = .required
            } else {
                // Fallback on earlier versions
            }
            
            mapView.addOverlay(circleOverlay)
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
        if let overlay = overlay as? ColorCircleOverlay {
            let renderer = MKCircleRenderer(circle: overlay)
            renderer.strokeColor = overlay.getColor()
            renderer.fillColor = overlay.getColor().withAlphaComponent(0.2)
            renderer.lineWidth = 2
            return renderer
        } else if let overlay = overlay as? BorderOverlay {
            let renderer = MKPolygonRenderer(overlay: overlay)
            //renderer.strokeColor = overlay.getColor()
            renderer.strokeColor = overlay.getColor()
            renderer.lineWidth = 4
            return renderer
        }
        
        //if let overlay = overlay as?
        
        return MKOverlayRenderer(overlay: overlay)
    }
}
