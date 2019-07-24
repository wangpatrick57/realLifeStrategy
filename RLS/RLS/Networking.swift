//
//  Networking.swift
//  RLS
//
//  Created by Patrick Wang on 6/3/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//

import Foundation
import MapKit

class Networking {
    var inputStream: InputStream!
    var outputStream: OutputStream!
    var username = ""
    var maxReadLength = 1024
    var doSendRec = true
    var doSendLoc = true
    var btReceived = true
    var idExists: Bool? = nil
    var nameExists: Bool? = nil
    var locPlaces = 5
    
    let posInc: [String: Int] = [
        "bt": 1,
        "rp": 3,
        "checkID": 2,
        "checkName": 2,
        "loc": 4,
        "team": 3,
        "dead": 3,
        "ward": 4,
        "conn": 3,
    ]
    
    func setupNetworkComms() {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, "73.189.41.182" /*"10.21.129.1"*/ as CFString, 8888, &readStream, &writeStream)

        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()
        inputStream.schedule(in: .current, forMode: RunLoop.Mode.common)
        outputStream.schedule(in: .current, forMode: RunLoop.Mode.common)
        inputStream.open()
        outputStream.open()
        
        write(str: "connected:")
    }
    
    func closeNetworkComms() {
        inputStream.close()
        outputStream.close()
    }
    
    func write(str: String) {
        outputStream.write(str, maxLength: str.count)
    }
    
    func sendHeartbeat() {
        if (btReceived) {
            write(str: "hrt:")
            btReceived = false
        }
    }
    
    func checkGameIDTaken(idToCheck: String) -> Bool {
        write(str: "checkID:\(idToCheck):")
        print("checking if gameID exists")
        var ret = true
        
        while (true) {
            readAllData()
            
            if let exists = idExists {
                ret = exists
                idExists = nil
                break
            }
        }
        
        return ret
    }
    
    func checkNameTaken(nameToCheck: String) -> Bool {
        write(str: "checkName:\(nameToCheck):")
        print("checking if name is taken")
        var ret = true
        
        while (true) {
            readAllData()
            
            if let exists = nameExists {
                ret = exists
                nameExists = nil
                break
            }
        }
        
        return ret
    }
    
    func sendReceiving() {
        if (doSendRec) {
            write(str: "rec:")
            doSendRec = false
        }
    }
    
    func checkIfSendLocation() {
        if (inputStream.hasBytesAvailable) {
            doSendLoc = true
        }
    }
    
    func sendLocation(coord: CLLocationCoordinate2D) {
        let state = UIApplication.shared.applicationState
        
        if (state == .background || state == .inactive) {
            checkIfSendLocation()
        }
        
        if (doSendLoc) {
            write(str: "loc:\(truncate(num: coord.latitude, places: locPlaces)):\(truncate(num: coord.longitude, places: locPlaces)):")
            doSendLoc = false
        }
    }
    
    func sendWardLoc(coord: CLLocationCoordinate2D) {
        write(str: "ward:\(truncate(num: coord.latitude, places: locPlaces)):\(truncate(num: coord.longitude, places: locPlaces)):")
    }
    
    func sendDead(dead: Bool) {
        write(str: "dead:\(dead):")
    }
    
    func sendTeam(team: String) {
        write(str: "team:\(team):")
    }
    
    func sendRet() {
        write(str: "ret:")
    }
    
    func readAllData() {
        let stringArray = read()
        print("Read \(stringArray)")
        
        if (stringArray.count > 1) {
            doSendRec = true
            doSendLoc = true
        }
        
        var posInArray = 0
        
        while (posInArray < stringArray.count - 1) {
            let bufType = stringArray[posInArray]
            
            switch bufType {
            case "bt":
                btReceived = true
                print("got beat")
            case "checkID":
                if let exists = Bool(stringArray[posInArray + 1]) {
                    idExists = exists
                } else {
                    print("checkID gave an invalid value")
                }
            case "checkName":
                if let exists = Bool(stringArray[posInArray + 1]) {
                    nameExists = exists
                } else {
                    print("checkName gave an invalid value")
                }
            case "rp":
                if let thisLat = Double(stringArray[posInArray + 1]) {
                    if let thisLong = Double(stringArray[posInArray + 2]) {
                        mapViewController.addRP(name: "Respawn Point", coordinate: CLLocationCoordinate2D(latitude: thisLat, longitude: thisLong))
                    } else {
                        print("rp long wrong")
                    }
                } else {
                    print("rp lat wrong")
                }
            case "team":
                let thisName = stringArray[posInArray + 1]
                let thisTeam = stringArray[posInArray + 2]
                mapViewController.updatePlayerTeam(name: thisName, team: thisTeam)
            case "loc":
                if let thisLat = Double(stringArray[posInArray + 2]) {
                    if let thisLong = Double(stringArray[posInArray + 3]) {
                        let thisName = stringArray[posInArray + 1]
                        mapViewController.updatePlayerLoc(name: thisName, lat: thisLat, long: thisLong)
                    }
                }
            case "dead":
                if let thisDead = Bool(stringArray[posInArray + 2]) {
                    let thisName = stringArray[posInArray + 1]
                    mapViewController.updatePlayerDead(name: thisName, dead: thisDead)
                }
            case "ward":
                if let thisLat = Double(stringArray[posInArray + 2]) {
                    if let thisLong = Double(stringArray[posInArray + 3]) {
                        if (thisLat != 0 || thisLong != 0) {
                            let thisName = stringArray[posInArray + 1]
                            mapViewController.updatePlayerWardLoc(name: thisName, lat: thisLat, long: thisLong)
                        }
                    }
                }
            case "conn":
                let thisName = stringArray[posInArray + 1]
                
                if let thisConn = Bool(stringArray[posInArray + 2]) {
                    mapViewController.updatePlayerConn(name: thisName, conn: thisConn)
                }
            default:
                _ = 1
            }
            
            if let inc = posInc[bufType] {
                posInArray += inc
            } else {
                print("bufType \(bufType) does not exist")
                print("buffer that gave error: \(stringArray)")
            }
        }
    }
    
    func read() -> [String] {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxReadLength)
        
        while inputStream.hasBytesAvailable {
            let numberOfBytesRead = inputStream.read(buffer, maxLength: maxReadLength)
            
            if (numberOfBytesRead < 0) {
                if let _ = inputStream.streamError {
                    break
                }
            }
            
            guard let stringArray = String(bytesNoCopy: buffer, length: numberOfBytesRead, encoding: .ascii, freeWhenDone: true)?.components(separatedBy: ":") else {
                return [""]
            }
            
            return stringArray
        }
        
        return [""]
    }
    
    func truncate(num: Double, places: Int) -> Double {
        return Double(floor(pow(10.0, Double(places)) * num) / pow(10.0, Double(places)))
    }
}
