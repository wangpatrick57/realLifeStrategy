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
    var username = ""
    var maxReadLength = 1024
    var idExists: Bool? = nil
    var nameExists: Bool? = nil
    var dataString = ""
    var controlPoint: ControlPoint? = nil
    let hostUDP: NWEndpoint.Host = "73.189.41.182"
    var portUDP: NWEndpoint.Port = 8889
    var connection: NWConnection? = nil
    var sendBorderPoints: [Bool] = []
    var sendRespawnPoints: [Bool] = []
    var sendRecBP: [Bool] = []
    var sendRecRP: [Bool] = []
    var sendBPCt = false
    var sendRPCt = false
    var sendUUID = false
    var sendWard = false
    var sendTeam = false
    var sendDead = false
    var sendDC = false
    let math: SpecMath = SpecMath()
    var timeSinceLastMessage = 0
    var writeString = ""
    
    let posInc: [String: Int] = [
        "bt": 1,
        "bp": 4,
        "rp": 4,
        "checkID": 2,
        "checkName": 2,
        "loc": 4,
        "team": 3,
        "dead": 3,
        "ward": 4,
        "dc": 2,
        "bpCt": 2,
        "rpCt": 2,
        "uuidCk": 2,
        "bpCk": 4,
        "rpCk": 4,
        "wardCk": 3,
        "teamCk": 2,
        "deadCk": 2,
        "dcCk": 1,
    ]
    
    func setupNetworkComms() {
        connection = NWConnection(host: hostUDP, port: portUDP, using: .udp)
        
        connection?.stateUpdateHandler = { (newState) in
            print("This is stateUpdateHandler:")
            switch (newState) {
            case .ready:
                print("State: Ready\n")
                self.addToWriteString("connected:")
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
        
        connection?.start(queue: .global())
        sendUUID = true
        
        let readQueue = DispatchQueue(label: "readQueue", qos: .background)
        
        readQueue.async {
            self.readData()
        }
    }
    
    func networkingBackgroundStep() {
        networking.sendHeartbeat()
        networking.reconnectIfNecessary()
        networking.broadcastOneTimers()
        networking.write()
    }
    
    func networkingForegroundStep() {
        networking.processData()
    }
    
    func processData() {
        let stringArray = dataString.components(separatedBy: ":")
        dataString = ""
        print("read \(stringArray)")
        
        if (stringArray.count > 1) {
            timeSinceLastMessage = 0
        }
        
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
            case "bp":
                if let index = Int(stringArray[posInArray + 1]) {
                    if let thisLat = Double(stringArray[posInArray + 2]) {
                        if let thisLong = Double(stringArray[posInArray + 3]) {
                            mapViewController?.addBorderPoint(index: index, coordinate: CLLocationCoordinate2D(latitude: thisLat, longitude: thisLong))
                            
                            while (sendRecBP.count <= index) {
                                sendRecBP.append(true)
                            }
                            
                            sendRecBP[index] = false
                        } else {
                            print("bp long wrong")
                        }
                    } else {
                        print("bp lat wrong")
                    }
                } else {
                    print("index wrong")
                }
            case "rp":
                if let index = Int(stringArray[posInArray + 1]) {
                    if let thisLat = Double(stringArray[posInArray + 2]) {
                        if let thisLong = Double(stringArray[posInArray + 3]) {
                            mapViewController?.addRespawnPoint(index: index, coordinate: CLLocationCoordinate2D(latitude: thisLat, longitude: thisLong))
                            
                            while (sendRecRP.count <= index) {
                                sendRecRP.append(true)
                            }
                            
                            sendRecRP[index] = false
                        } else {
                            print("rp long wrong")
                        }
                    } else {
                        print("rp lat wrong")
                    }
                } else {
                    print("rp index wrong")
                }
            case "bpCt":
                if let count = Int(stringArray[posInArray + 1]) {
                    sendRecBP = []
                    
                    for _ in 0..<count {
                        sendRecBP.append(true)
                    }
                    
                    sendBPCt = false
                } else {
                    print("count for bpCt error")
                }
            case "rpCt":
                if let count = Int(stringArray[posInArray + 1]) {
                    sendRecRP = []
                    
                    for _ in 0..<count {
                        sendRecRP.append(true)
                    }
                    
                    sendRPCt = false
                } else {
                    print("count for bpCt error")
                }
            case "uuidCk":
                let recUUID = stringArray[posInArray + 1]
                
                if (recUUID == uuid) {
                    sendUUID = false
                } else {
                    sendUUID = true
                }
            case "bpCk":
                if let index = Int(stringArray[posInArray + 1]) {
                    if let thisLat = Double(stringArray[posInArray + 2]) {
                        if let thisLong = Double(stringArray[posInArray + 3]) {
                            let coord = createdBorderPoints[index].getCoordinate()
                            
                            if (thisLat == coord.latitude && thisLong == coord.longitude) {
                                sendBorderPoints[index] = false
                            } else {
                                sendBorderPoints[index] = true
                            }
                        } else {
                            print("bpCk lat bad")
                        }
                    } else {
                        print("bpCk long bad")
                    }
                } else {
                    print("index for bpCk error")
                }
            case "rpCk":
                if let index = Int(stringArray[posInArray + 1]) {
                    if let thisLat = Double(stringArray[posInArray + 2]) {
                        if let thisLong = Double(stringArray[posInArray + 3]) {
                            if (createdRespawnPoints.indices.contains(index)) {
                                let coord = createdRespawnPoints[index].getCoordinate()
                                
                                if (thisLat == coord.latitude && thisLong == coord.longitude) {
                                    sendRespawnPoints[index] = false
                                } else {
                                    sendRespawnPoints[index] = true
                                }
                            } else {
                                print("index for rpCk oob")
                            }
                        } else {
                            print("rpCk lat bad")
                        }
                    } else {
                        print("rpCk long bad")
                    }
                } else {
                    print("index for rpCk error")
                }
            case "wardCk":
                if let thisLat = Double(stringArray[posInArray + 1]) {
                    if let thisLong = Double(stringArray[posInArray + 2]) {
                        if let myWard = myPlayer.getWard() {
                            let coord = myWard.getCoordinate()
                            
                            if (thisLat == coord.latitude && thisLong == coord.longitude) {
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
                posInArray += 1
            }
        }
    }
    
    func reconnectIfNecessary() {
        timeSinceLastMessage += 1
        
        if (timeSinceLastMessage >= disconnectTimeout) {
            print("rec if nec called")
            networking.closeNetworkComms()
            networking.setupNetworkComms()
            
            //reinitialize
            timeSinceLastMessage = 0
        }
    }
    
    func broadcastOneTimers() {
        for i in 0..<sendBorderPoints.count {
            if (sendBorderPoints[i]) {
                sendBorderPoint(index: i)
            }
        }
        
        for i in 0..<sendRespawnPoints.count {
            if (sendRespawnPoints[i]) {
                sendRespawnPoint(index: i)
            }
        }
        
        if (sendUUID) {
            sendUUIDFunc()
        }
        
        if (sendBPCt) {
            sendBorderPointCount()
        }
        
        if (sendRPCt) {
            sendRespawnPointCount()
        }
        
        for i in 0..<sendRecBP.count {
            if (sendRecBP[i]) {
                sendRecBPFunc(index: i)
            }
        }
        
        for i in 0..<sendRecRP.count {
            if (sendRecRP[i]) {
                sendRecRPFunc(index: i)
            }
        }
        
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
    }
    
    func readData() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, contentContext, isComplete, error) in
            if let error = error {
                print("\(error)")
                return
            }
            
            if let thisData = data {
                let thisDataString = String(decoding: thisData, as: UTF8.self)
                print("thisDataString: \(thisDataString)")
                self.dataString += thisDataString
            } else {
                print("Data is nil")
            }
            
            self.readData()
            return
        }
    }
    
    func addToWriteString(_ content: String) {
        writeString += content
    }
    
    func write() {
        if (Float.random(in: 0 ..< 1) > packetLossChance) {
            let contentToSendUDP = writeString.data(using: String.Encoding.utf8)
            print("Wrote \(self.writeString)")
            writeString = ""
            
            if let connObj = self.connection {
                /*connObj.send(content: contentToSendUDP, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
                    if (NWError == nil) {
                        print("Wrote \(content)")
                    } else {
                        print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
                    }
                })))*/
                connObj.send(content: contentToSendUDP, completion: .contentProcessed( { error in
                    if let error = error {
                        print("Error in sending: \(error)")
                        return
                    } else {
                    }
                }))
            } else {
                print("connObj is nil")
            }
        } else {
            print("data lost")
        }
    }
    
    func sendHeartbeat() {
        addToWriteString("hrt:")
    }
    
    func checkGameIDTaken(idToCheck: String, hostOrJoin: String) -> Bool {
        var ret = true
        idExists = nil
        
        while (true) {
            addToWriteString("checkID\(hostOrJoin):\(idToCheck):")
            write()
            processData()
            
            if let exists = idExists {
                print("idExists = \(exists)")
                ret = exists
                break
            } else {
                print("idExists is nil")
            }
            
            usleep(500000) //0.5 seconds
        }
        
        return ret
    }
    
    func checkNameTaken(nameToCheck: String) -> Bool {
        var ret = true
        nameExists = nil
        
        while (true) {
            addToWriteString("checkName:\(nameToCheck):")
            write()
            processData()
            
            if let exists = nameExists {
                ret = exists
                break
            }
            
            usleep(500000)
        }
        
        return ret
    }
    
    func sendUUIDFunc() {
        addToWriteString("uuid:\(uuid):")
    }
    
    func sendReceiving() {
        addToWriteString("rec:")
    }
    
    func sendLocation(coord: CLLocationCoordinate2D) {
        addToWriteString("loc:\(coord.latitude):\(coord.longitude):")
    }
    
    func sendWardLoc(coord: CLLocationCoordinate2D) {
        addToWriteString("ward:\(coord.latitude):\(coord.longitude):")
    }
    
    func sendDead(dead: Bool) {
        addToWriteString("dead:\(dead):")
    }
    
    func sendTeam(team: String) {
        addToWriteString("team:\(team):")
    }
    
    func sendFiveDC() {
        for _ in 1...5 {
            print("sending dc")
            sendDCFunc()
        }
        
        usleep(1000000)
    }
    
    func sendDCFunc() { //it can't be called sendDC cuz there's a variable called sendDC and this function has no parameters
        addToWriteString("dc:")
    }
    
    func sendRedPoint(point: Double) {
        addToWriteString("redPoint:\(point):")
    }
    
    func sendBluePoint(point: Double) {
        addToWriteString("bluePoint:\(point):")
    }
    
    func sendCPNums(numRed: Int, numBlue: Int) {
        addToWriteString("cp:\( controlPoint?.getLocation().latitude):\(controlPoint?.getLocation().longitude):\(numRed):\(numBlue):")
    }
    
    //have to send lat and long as cllocationcoordinate2d so that .latitude and .longitude are cllocationdegrees
    func sendCPLoc(lat: Double, long: Double) {
        if let cp = controlPoint {
            addToWriteString("cp:\(lat):\(long):\(cp.getNumRed()):\(cp.getNumBlue()):")
        }
    }
    
    func sendBorderPoint(index: Int) {
        let coord = createdBorderPoints[index].getCoordinate()
        let lat = math.truncate(num: coord.latitude)
        let long = math.truncate(num: coord.longitude)
        addToWriteString("bp:\(index):\(lat):\(long):")
    }
    
    func sendRespawnPoint(index: Int) {
        let respawnPoint = createdRespawnPoints[index]
        let coord = respawnPoint.getCoordinate()
        let lat = math.truncate(num: coord.latitude)
        let long = math.truncate(num: coord.longitude)
        addToWriteString("rp:\(index):\(lat):\(long):")
    }
    
    func sendBorderPointCount() {
        addToWriteString("bpCt:")
    }
    
    func sendRespawnPointCount() {
        addToWriteString("rpCt:")
    }
    
    func sendRecBPFunc(index: Int) {
        addToWriteString("recBP:\(index):")
    }
    
    func sendRecRPFunc(index: Int) {
        addToWriteString("recRP:\(index):")
    }
    
    func clearSendRecBP() {
        sendRecBP = []
    }
    
    func clearSendRecRP() {
        sendRecRP = []
    }
    
    func sendWardCheck(name: String, coord: CLLocationCoordinate2D) {
        addToWriteString("wardCk:\(name):\(coord.latitude):\(coord.longitude):")
    }
    
    func sendTeamCheck(name: String, team: String) {
        addToWriteString("teamCk:\(name):\(team):")
    }
    
    func sendDeadCheck(name: String, dead: Bool) {
        addToWriteString("deadCk:\(name):\(dead):")
    }
    
    func sendDCCheck(name: String) {
        addToWriteString("dcCk:\(name):")
    }
    
    func setSendBP(sb: Bool, index: Int) {
        while (sendBorderPoints.count <= index) {
            sendBorderPoints.append(false)
        }
        
        sendBorderPoints[index] = sb
    }
    
    func setSendRP(sr: Bool, index: Int) {
        while (sendRespawnPoints.count <= index) {
            sendRespawnPoints.append(false)
        }
        
        sendRespawnPoints[index] = sr
    }
    
    func setSendBPCt(sbc: Bool) {
        sendBPCt = sbc
    }
    
    func setSendRPCt(src: Bool) {
        sendRPCt = src
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
}
