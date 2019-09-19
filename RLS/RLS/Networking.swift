//
//  Networking.swift
//  RLS
//
//  Created by Patrick Wang on 6/3/19.
//  Copyright © 2019 Melody Lee. All rights reserved.
//

import Foundation
import MapKit
import Network

class Networking {
    var inputStream: InputStream!
    var outputStream: OutputStream!
    var username = ""
    var maxReadLength = 1024
    var idExists: Bool? = nil
    var nameExists: Bool? = nil
    var dataString = ""
    var locPlaces = 5
    var controlPoint: ControlPoint? = nil
    var connection: NWConnection?
    let hostUDP: NWEndpoint.Host = "73.189.41.182"
    var portUDP: NWEndpoint.Port = 8889
    var sendWard = false
    var sendTeam = false
    var sendDead = false
    var sendDC = false
    
    let posInc: [String: Int] = [
        "bt": 1,
        "rp": 3,
        "brd": 3,
        "checkID": 2,
        "checkName": 2,
        "loc": 4,
        "team": 3,
        "dead": 3,
        "ward": 4,
        "dc": 2,
        "wardCk": 3,
        "teamCk": 2,
        "deadCk": 2,
        "dcCk": 1,
    ]
    
    func setupNetworkComms() {
        connection = NWConnection(host: hostUDP, port: portUDP, using: .udp)
        
        self.connection?.stateUpdateHandler = { (newState) in
            print("This is stateUpdateHandler:")
            switch (newState) {
            case .ready:
                print("State: Ready\n")
                self.write("connected:")
            case .setup:
                print("State: Setup\n")
            case .cancelled:
                print("State: Cancelled\n")
            case .preparing:
                print("State: Preparing\n")
            default:
                print("ERROR! State not defined!\n")
            }
        }
        
        self.connection?.start(queue: .global())
    }
    
    func readAllData() {
        let stringArray = read()
        print("rad stringArray = \(stringArray)")
        var posInArray = 0
        
        while (posInArray < stringArray.count - 1) {
            let bufType = stringArray[posInArray]
            
            switch bufType {
            case "bt":
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
            case "team":
                let thisName = stringArray[posInArray + 1]
                let thisTeam = stringArray[posInArray + 2]
                
                if let mvc = mapViewController {
                    mvc.updatePlayerTeam(name: thisName, team: thisTeam)
                    sendTeamCheck(name: thisName, team: thisTeam)
                } else {
                    print("team packet: mvc doesn't exist")
                }
            case "loc":
                if let thisLat = Double(stringArray[posInArray + 2]) {
                    if let thisLong = Double(stringArray[posInArray + 3]) {
                        let thisName = stringArray[posInArray + 1]
                        mapViewController?.updatePlayerLoc(name: thisName, lat: thisLat, long: thisLong)
                    }
                }
            case "dead":
                if let thisDead = Bool(stringArray[posInArray + 2]) {
                    let thisName = stringArray[posInArray + 1]
                    
                    if let mvc = mapViewController {
                        mvc.updatePlayerDead(name: thisName, dead: thisDead)
                        sendDeadCheck(name: thisName, dead: thisDead)
                    } else {
                        print("team packet: mvc doesn't exist")
                    }
                }
            case "ward":
                if let thisLat = Double(stringArray[posInArray + 2]) {
                    if let thisLong = Double(stringArray[posInArray + 3]) {
                        if (thisLat != 0 || thisLong != 0) {
                            let thisName = stringArray[posInArray + 1]
                            
                            if let mvc = mapViewController {
                                mvc.updatePlayerWardLoc(name: thisName, lat: thisLat, long: thisLong)
                                sendWardCheck(name: thisName, coord: CLLocationCoordinate2D(latitude: thisLat, longitude: thisLong))
                            } else {
                                print("team packet: mvc doesn't exist")
                            }
                        }
                    }
                }
            case "redPoint":
                if let p = Double(stringArray[posInArray + 1]){
                    controlPoint?.setRedPoints(point: p)
                }
            case "bluePoint":
                if let p = Double(stringArray[posInArray + 1]){
                    controlPoint?.setBluePoints(point: p)
                }
            case "cp":
                if let lat = Double(stringArray[posInArray + 1]){
                    if let long = Double(stringArray[posInArray + 2]){
                        controlPoint?.setCoordinate(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long))
                    }
                }
                if let nr = Int(stringArray[posInArray + 3]) {
                    controlPoint?.setNumRed(numRed: nr)
                }
                if let nb = Int(stringArray[posInArray + 4]) {
                    controlPoint?.setNumRed(numRed: nb)
                }
                
            case "dc":
                let thisName = stringArray[posInArray + 1]
                if let mvc = mapViewController {
                    mvc.playerDC(name: thisName)
                    sendDCCheck(name: thisName)
                } else {
                    print("team packet: mvc doesn't exist")
                }
            case "brd":
                if let thisLat = Double(stringArray[posInArray + 1]) {
                    if let thisLong = Double(stringArray[posInArray + 2]) {
                        mapViewController?.addBoord(boord: CLLocation(latitude: thisLat, longitude: thisLong))
                    } else {
                        print("brd long wrong")
                    }
                } else {
                    print("brd lat wrong")
                }
                
                recBrd = false
            case "rp":
                if let thisLat = Double(stringArray[posInArray + 1]) {
                    if let thisLong = Double(stringArray[posInArray + 2]) {
                        mapViewController?.addRP(name: "Respawn Point", coordinate: CLLocationCoordinate2D(latitude: thisLat, longitude: thisLong))
                    } else {
                        print("rp long wrong")
                    }
                } else {
                    print("rp lat wrong")
                }
                
                recRP = false
            case "wardCk":
                if let thisLat = Double(stringArray[posInArray + 1]) {
                    if let thisLong = Double(stringArray[posInArray + 2]) {
                        if let myWard = myPlayer.getWard() {
                            let coord = myWard.getCoordinate()
                            
                            if (thisLat == truncate(num: coord.latitude, places: locPlaces) && thisLong == truncate(num: coord.longitude, places: locPlaces)) {
                                sendWard = false
                            } else {
                                sendWard = true
                            }
                        }
                    } else {
                        print("wardCk long wrong")
                    }
                } else {
                    print("wardCk lat wrong")
                }
            case "teamCk":
                let thisTeam = stringArray[posInArray + 1]
                
                if (thisTeam == myPlayer.getTeam()) {
                    sendTeam = false
                } else {
                    sendTeam = true
                }
                
                print("sendTeam = \(sendTeam)")
            case "deadCk":
                if let thisDead = Bool(stringArray[posInArray + 1]) {
                    if (thisDead == myPlayer.getDead()) {
                        sendDead = false
                    } else {
                        sendDead = true
                    }
                } else {
                    print("deadCk dead wrong")
                }
            case "dcCk":
                sendDC = false
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
    
    func broadcastOneTimers() {
        if (sendWard) {
            if let myWard = myPlayer.getWard() {
                sendWardLoc(coord: myWard.getCoordinate())
            }
        }
        
        if (sendTeam) {
            sendTeam(team: myPlayer.getTeam())
        }
        
        if (sendDead) {
            sendDead(dead: myPlayer.getDead())
        }
        
        if (sendDC) {
            sendDCFunc()
        }
    }
    
    func closeNetworkComms() {
        inputStream.close()
        outputStream.close()
    }
    
    func read() -> [String] {
        for _ in 1...5 {
            self.connection?.receiveMessage { (data, context, isComplete, error) in
                if (data != nil) {
                    self.dataString += String(decoding: data!, as: UTF8.self)
                } else {
                    print("Data is nil")
                }
            }
        }
        
        let stringArray = dataString.components(separatedBy: ":")
        dataString = ""
        return stringArray
    }
    
    func write(_ content: String) {
        if (Float.random(in: 0 ..< 1) > packetLossChance) {
            let contentToSendUDP = content.data(using: String.Encoding.utf8)
            
            if let connObj = self.connection {
                connObj.send(content: contentToSendUDP, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
                    if (NWError == nil) {
                        print("Wrote \(content)")
                    } else {
                        print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
                    }
                })))
            } else {
                print("connObj is nil")
            }
        } else {
            print("data lost")
        }
    }
    
    func sendHeartbeat() {
        write("hrt:")
    }
    
    func checkGameIDTaken(idToCheck: String) -> Bool {
        var ret = true
        idExists = nil
        
        while (true) {
            write("checkID:\(idToCheck):")
            readAllData()
            
            if let exists = idExists {
                print("idExists = \(exists)")
                ret = exists
                break
            } else {
                print("idExists is nil")
            }
            
            usleep(500000)
        }
        
        return ret
    }
    
    func checkNameTaken(nameToCheck: String) -> Bool {
        var ret = true
        nameExists = nil
        
        while (true) {
            write("checkName:\(nameToCheck):")
            readAllData()
            
            if let exists = nameExists {
                ret = exists
                break
            }
            
            usleep(500000)
        }
        
        return ret
    }
    
    func sendReceiving() {
        write("rec:")
    }
    
    func sendLocation(coord: CLLocationCoordinate2D) {
        write("loc:\(truncate(num: coord.latitude, places: locPlaces)):\(truncate(num: coord.longitude, places: locPlaces)):")
    }
    
    func sendWardLoc(coord: CLLocationCoordinate2D) {
        write("ward:\(truncate(num: coord.latitude, places: locPlaces)):\(truncate(num: coord.longitude, places: locPlaces)):")
    }
    
    func sendDead(dead: Bool) {
        write("dead:\(dead):")
    }
    
    func sendTeam(team: String) {
        write("team:\(team):")
    }
    
    func sendDCFunc() { //it can't be called sendDC cuz there's a variable called sendDC and this function has no parameters
        write("dc:")
    }
    
    func sendRet() {
        write("ret:")
    }
    
    func sendRedPoint(point: Double) {
        write("redPoint:\(point):")
    }
    
    func sendBluePoint(point: Double) {
        write("bluePoint:\(point):")
    }
    
    func sendCPNums(numRed: Int, numBlue: Int) {
        write("cp:\( controlPoint?.getLocation().latitude):\(controlPoint?.getLocation().longitude):\(numRed):\(numBlue):")
    }
    
    //have to send lat and long as cllocationcoordinate2d so that .latitude and .longitude are cllocationdegrees
    func sendCPLoc(lat: Double, long: Double) {
        if let cp = controlPoint {
            write("cp:\(lat):\(long):\(cp.getNumRed()):\(cp.getNumBlue()):")
        }
    }
    
    func sendBoord(boord: CLLocation) {
        let lat = truncate(num: boord.coordinate.latitude, places: locPlaces)
        let long = truncate(num: boord.coordinate.longitude, places: locPlaces)
        write("brd:\(lat):\(long):")
    }
    
    func sendRecBrd() {
        write("recBrd:")
    }
    
    func sendRecRP() {
        write("recRP:")
    }
    
    func sendWardCheck(name: String, coord: CLLocationCoordinate2D) {
        write("wardCk:\(name):\(truncate(num: coord.latitude, places: locPlaces)):\(truncate(num: coord.longitude, places: locPlaces)):")
    }
    
    func sendTeamCheck(name: String, team: String) {
        write("teamCk:\(name):\(team):")
    }
    
    func sendDeadCheck(name: String, dead: Bool) {
        write("deadCk:\(name):\(dead):")
    }
    
    func sendDCCheck(name: String) {
        write("dcCk:\(name):")
    }
    
    func setSendWard(sw: Bool) {
        sendWard = sw
    }
    
    func setSendTeam(st: Bool) {
        sendTeam = st
        print("sendTeam set to \(st)")
    }
    
    func setSendDead(sd: Bool) {
        sendDead = sd
    }
    
    func setSendDC(sd: Bool) {
        sendDC = sd
    }
    
    func truncate(num: Double, places: Int) -> Double {
        return Double(floor(pow(10.0, Double(places)) * num) / pow(10.0, Double(places)))
    }
}
