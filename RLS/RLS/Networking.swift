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

let UUID = 0
let UUID_CK = 1
let HEART = 2
let BEAT = 3
let CONN = 4
let TOGGLE_RDL = 5
let TOGGLE_PP = 6
let SIM_CLIENT = 7
let CHECK_ID = 8
let CHECK_ID_H = 9
let CHECK_ID_J = 10
let CHECK_NAME = 11
let BK = 12
let BK_CK = 13
let TEAM = 14
let LOC = 15
let WARD = 16
let DEAD = 17
let DC = 18
let RESET = 19
let BP = 20
let RP = 21
let BP_CK = 22
let RP_CK = 23
let BP_CT = 24
let RP_CT = 25
let REC_BP = 26
let REC_RP = 27
let WARD_CK = 28
let TEAM_CK = 29
let DEAD_CK = 30
let DC_CK = 31

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
    var sendBK = false
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
    
    let posInc: [Int: Int] = [
        BEAT: 1,
        BP: 4,
        RP: 4,
        CHECK_ID: 2,
        CHECK_NAME: 2,
        BK_CK: 2,
        LOC: 4,
        TEAM: 3,
        DEAD: 3,
        WARD: 4,
        DC: 2,
        BP_CT: 2,
        RP_CT: 2,
        UUID_CK: 2,
        BP_CK: 4,
        RP_CK: 4,
        WARD_CK: 3,
        TEAM_CK: 2,
        DEAD_CK: 2,
        DC_CK: 1,
    ]
    
    func setupNetworkComms() {
        cleanup()
        
        connection = NWConnection(host: hostUDP, port: portUDP, using: .udp)
        
        connection?.stateUpdateHandler = { (newState) in
            print("This is stateUpdateHandler:")
            switch (newState) {
            case .ready:
                print("State: Ready\n")
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
    
    func cleanup() {
        writeString = ""
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
            var bufType = -1
            
            if let intBufType = Int(stringArray[posInArray]) {
                bufType = intBufType
            } else {
                posInArray += 1
                continue
            }
            
            switch bufType {
            case BEAT:
                print("got beat")
            case CHECK_ID:
                if let exists = Bool(stringArray[posInArray + 1]) {
                    idExists = exists
                } else {
                    print("checkID gave an invalid value")
                }
            case CHECK_NAME:
                if let exists = Bool(stringArray[posInArray + 1]) {
                    nameExists = exists
                } else {
                    print("checkName gave an invalid value")
                }
            case BK_CK:
                if let bk = Bool(stringArray[posInArray + 1]) {
                    if bk == (UIApplication.shared.applicationState == .background) {
                        sendBK = false
                    } else {
                        sendBK = true
                    }
                } else {
                    print("bk_ck gave a non boolean value")
                }
            case TEAM:
                let thisName = stringArray[posInArray + 1]
                let thisTeam = stringArray[posInArray + 2]
                
                if let mvc = mapViewController {
                    mvc.updatePlayerTeam(name: thisName, team: thisTeam)
                    sendTeamCheck(name: thisName, team: thisTeam)
                } else {
                    print("team packet: mvc doesn't exist")
                }
            case LOC:
                if let thisLat = Double(stringArray[posInArray + 2]) {
                    if let thisLong = Double(stringArray[posInArray + 3]) {
                        let thisName = stringArray[posInArray + 1]
                        mapViewController?.updatePlayerLoc(name: thisName, lat: thisLat, long: thisLong)
                    }
                }
            case DEAD:
                if let thisDead = Bool(stringArray[posInArray + 2]) {
                    let thisName = stringArray[posInArray + 1]
                    
                    if let mvc = mapViewController {
                        mvc.updatePlayerDead(name: thisName, dead: thisDead)
                        sendDeadCheck(name: thisName, dead: thisDead)
                    } else {
                        print("team packet: mvc doesn't exist")
                    }
                }
            case WARD:
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
            case DC:
                let thisName = stringArray[posInArray + 1]
                if let mvc = mapViewController {
                    mvc.playerDC(name: thisName)
                    sendDCCheck(name: thisName)
                } else {
                    print("team packet: mvc doesn't exist")
                }
            case BP:
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
            case RP:
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
            case BP_CT:
                if let count = Int(stringArray[posInArray + 1]) {
                    sendRecBP = []
                    
                    for _ in 0..<count {
                        sendRecBP.append(true)
                    }
                    
                    sendBPCt = false
                } else {
                    print("count for bpCt error")
                }
            case RP_CT:
                if let count = Int(stringArray[posInArray + 1]) {
                    sendRecRP = []
                    
                    for _ in 0..<count {
                        sendRecRP.append(true)
                    }
                    
                    sendRPCt = false
                } else {
                    print("count for bpCt error")
                }
            case UUID_CK:
                let recUUID = stringArray[posInArray + 1]
                
                if (recUUID == uuid) {
                    sendUUID = false
                } else {
                    sendUUID = true
                }
            case BP_CK:
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
            case RP_CK:
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
            case WARD_CK:
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
            case TEAM_CK:
                let thisTeam = stringArray[posInArray + 1]
                
                if (thisTeam == myPlayer.getTeam()) {
                    sendTeam = false
                } else {
                    sendTeam = true
                }
                
                print("sendTeam = \(sendTeam)")
            case DEAD_CK:
                if let thisDead = Bool(stringArray[posInArray + 1]) {
                    if (thisDead == myPlayer.getDead()) {
                        sendDead = false
                    } else {
                        sendDead = true
                    }
                } else {
                    print("deadCk dead wrong")
                }
            case DC_CK:
                print("dc ck received.ddxssxszsz xzxx z1q   awqs43e 54234")
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
        
        if (sendBK) {
            sendBKFunc(bk: UIApplication.shared.applicationState == .background)
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
        connection?.cancel()
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
    
    func sendConnected() {
        addToWriteString("\(CONN):")
    }
    
    func sendHeartbeat() {
        addToWriteString("\(HEART):")
    }
    
    func checkGameIDTaken(idToCheck: String, hostOrJoin: String) -> Bool {
        var ret = true
        idExists = nil
        var checkIDCode = 0
        
        if (hostOrJoin == "h") {
            checkIDCode = CHECK_ID_H
        } else if (hostOrJoin == "j") {
            checkIDCode = CHECK_ID_J
        }
        
        while (true) {
            addToWriteString("\(checkIDCode):\(idToCheck):")
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
            addToWriteString("\(CHECK_NAME):\(nameToCheck):")
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
        addToWriteString("\(UUID):\(uuid):")
    }
    
    func sendBKFunc(bk: Bool) {
        addToWriteString("\(BK):\(bk):")
    }
    
    func sendLocation(coord: CLLocationCoordinate2D) {
        addToWriteString("\(LOC):\(coord.latitude):\(coord.longitude):")
    }
    
    func sendWardLoc(coord: CLLocationCoordinate2D) {
        addToWriteString("\(WARD):\(coord.latitude):\(coord.longitude):")
    }
    
    func sendDead(dead: Bool) {
        addToWriteString("\(DEAD):\(dead):")
    }
    
    func sendTeam(team: String) {
        addToWriteString("\(TEAM):\(team):")
    }
    
    func sendFiveDC() {
        for _ in 1...5 {
            print("sending dc")
            sendDCFunc()
        }
        
        usleep(1000000)
    }
    
    func sendDCFunc() { //it can't be called sendDC cuz there's a variable called sendDC and this function has no parameters
        addToWriteString("\(DC):")
    }
    
    func sendBorderPoint(index: Int) {
        let coord = createdBorderPoints[index].getCoordinate()
        let lat = math.truncate(num: coord.latitude)
        let long = math.truncate(num: coord.longitude)
        addToWriteString("\(BP):\(index):\(lat):\(long):")
    }
    
    func sendRespawnPoint(index: Int) {
        let coord = createdRespawnPoints[index].getCoordinate()
        let lat = math.truncate(num: coord.latitude)
        let long = math.truncate(num: coord.longitude)
        addToWriteString("\(RP):\(index):\(lat):\(long):")
    }
    
    func sendBorderPointCount() {
        addToWriteString("\(BP_CT):")
    }
    
    func sendRespawnPointCount() {
        addToWriteString("\(RP_CT):")
    }
    
    func sendRecBPFunc(index: Int) {
        addToWriteString("\(REC_BP):\(index):")
    }
    
    func sendRecRPFunc(index: Int) {
        addToWriteString("\(REC_RP):\(index):")
        print("sendRecRPFunc called with index = \(index)")
    }
    
    func clearSendRecBP() {
        sendRecBP = []
    }
    
    func clearSendRecRP() {
        sendRecRP = []
    }
    
    func sendWardCheck(name: String, coord: CLLocationCoordinate2D) {
        addToWriteString("\(WARD_CK):\(name):\(coord.latitude):\(coord.longitude):")
    }
    
    func sendTeamCheck(name: String, team: String) {
        addToWriteString("\(TEAM_CK):\(name):\(team):")
    }
    
    func sendDeadCheck(name: String, dead: Bool) {
        addToWriteString("\(DEAD_CK):\(name):\(dead):")
    }
    
    func sendDCCheck(name: String) {
        addToWriteString("\(DC_CK):\(name):")
    }
    
    func setSendBK(sb: Bool) {
        sendBK = sb
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
