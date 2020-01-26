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

let MAX_READ_LENGTH = 1024

class Networking {
    var username = ""
    var idExists: Bool? = nil
    var nameExists: Bool? = nil
    var udpSocket: UDPSocket!
    let host: String = "73.189.41.182"
    var port: UInt16 = 8889
    var sendBP: [Bool] = []
    var sendRP: [Bool] = []
    var sendRecBP: [Bool] = []
    var sendRecRP: [Bool] = []
    
    var sendOneTimer: [Int: Bool] = [
        BK: false,
        BP_CT: false,
        RP_CT: false,
        UUID: false,
        WARD: false,
        TEAM: false,
        DEAD: false,
        DC: false,
    ]
    
    let math: SpecMath = SpecMath()
    var timeSinceLastMessage = 0
    var writeString = ""
    
    func setupNetworkComms() {
        udpSocket = UDPSocket(host: host, port: port)
        udpSocket.setupConnection()
        
        sendOneTimer[UUID] = true
        
        _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(networkingStep), userInfo: nil, repeats: true)
    }
    
    @objc func networkingStep() {
        DispatchQueue.global(qos: .utility).async {
            networking.processData()
            networking.sendHeartbeat()
            networking.reconnectIfNecessary()
            networking.broadcastOneTimers()
            networking.flush()
        }
    }
    
    func processData() {
        let stringArray = udpSocket.popDataString().components(separatedBy: ":")
        
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
                    if bk == inBackground {
                        sendOneTimer[BK] = false
                    } else {
                        sendOneTimer[BK] = true
                    }
                } else {
                    print("bk_ck gave a non boolean value")
                }
            case TEAM:
                let thisName = stringArray[posInArray + 1]
                let thisTeam = stringArray[posInArray + 2]
                
                if let mvc = mapViewController {
                    DispatchQueue.main.async {
                        mvc.updatePlayerTeam(name: thisName, team: thisTeam)
                    }
                    
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
                        DispatchQueue.main.async {
                            mvc.updatePlayerDead(name: thisName, dead: thisDead)
                        }
                        
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
                                DispatchQueue.main.async {
                                    mvc.updatePlayerWardLoc(name: thisName, lat: thisLat, long: thisLong)
                                }
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
                    DispatchQueue.main.async {
                        mvc.playerDC(name: thisName)
                    }
                    
                    sendDCCheck(name: thisName)
                } else {
                    print("team packet: mvc doesn't exist")
                }
            case BP:
                if let index = Int(stringArray[posInArray + 1]) {
                    if let thisLat = Double(stringArray[posInArray + 2]) {
                        if let thisLong = Double(stringArray[posInArray + 3]) {
                            if let mvc = mapViewController {
                                DispatchQueue.main.async {
                                    mvc.addBorderPoint(index: index, coordinate: CLLocationCoordinate2D(latitude: thisLat, longitude: thisLong))
                                }
                                
                                while (sendRecBP.count <= index) {
                                    sendRecBP.append(true)
                                }
                                
                                sendRecBP[index] = false
                            } else {
                                print("BP: mvc doesn't exist")
                            }
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
                    
                    sendOneTimer[BP_CT] = false
                } else {
                    print("count for bpCt error")
                }
            case RP_CT:
                if let count = Int(stringArray[posInArray + 1]) {
                    sendRecRP = []
                    
                    for _ in 0..<count {
                        sendRecRP.append(true)
                    }
                    
                    sendOneTimer[RP_CT] = false
                } else {
                    print("count for bpCt error")
                }
            case UUID_CK:
                let recUUID = stringArray[posInArray + 1]
                
                if (recUUID == uuid) {
                    sendOneTimer[UUID] = false
                } else {
                    sendOneTimer[UUID] = true
                }
            case BP_CK:
                if let index = Int(stringArray[posInArray + 1]) {
                    if let thisLat = Double(stringArray[posInArray + 2]) {
                        if let thisLong = Double(stringArray[posInArray + 3]) {
                            let coord = createdBorderPoints[index].getCoordinate()
                            
                            if (thisLat == coord.latitude && thisLong == coord.longitude) {
                                sendBP[index] = false
                            } else {
                                sendBP[index] = true
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
                                    sendRP[index] = false
                                } else {
                                    sendRP[index] = true
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
                                sendOneTimer[WARD] = false
                            } else {
                                sendOneTimer[WARD] = true
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
                    sendOneTimer[TEAM] = false
                } else {
                    sendOneTimer[TEAM] = true
                }
                
                print("sendTeam = \(sendOneTimer[TEAM]!)")
            case DEAD_CK:
                if let thisDead = Bool(stringArray[posInArray + 1]) {
                    if (thisDead == myPlayer.getDead()) {
                        sendOneTimer[DEAD] = false
                    } else {
                        sendOneTimer[DEAD] = true
                    }
                } else {
                    print("deadCk dead wrong")
                }
            case DC_CK:
                print("dc ck received.ddxssxszsz xzxx z1q   awqs43e 54234")
                sendOneTimer[DC] = false
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
        for i in 0..<sendBP.count {
            if (sendBP[i]) {
                sendBorderPoint(index: i)
            }
        }
        
        for i in 0..<sendRP.count {
            if (sendRP[i]) {
                sendRespawnPoint(index: i)
            }
        }
        
        if (sendOneTimer[UUID]!) {
            sendUUIDFunc()
        }
        
        if (sendOneTimer[BK]!) {
            sendBKFunc(bk: inBackground)
        }
        
        if (sendOneTimer[BP_CT]!) {
            sendBorderPointCount()
        }
        
        if (sendOneTimer[RP_CT]!) {
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
        
        if (sendOneTimer[WARD]!) {
            if let myWard = myPlayer.getWard() {
                sendWardLoc(coord: myWard.getCoordinate())
            }
        }
        
        if (sendOneTimer[TEAM]!) {
            sendTeam(team: myPlayer.getTeam())
        }
        
        if (sendOneTimer[DEAD]!) {
            sendDead(dead: myPlayer.getDead())
        }
        
        if (sendOneTimer[DC]!) {
            sendDCFunc()
        }
    }
    
    func closeNetworkComms() {
        writeString = ""
    }
    
    func addToWriteString(_ content: String) {
        writeString += content
    }
    
    func flush() {
        if (Float.random(in: 0 ..< 1) > packetLossChance) {
            udpSocket.send(message: writeString)
            writeString = ""
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
            flush()
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
            flush()
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
    
    func setSendOneTimer(key: Int, value: Bool) {
        sendOneTimer[key] = value
    }
    
    func setSendBP(value: Bool, index: Int) {
        sendBP[index] = value
    }
    
    func setSendRP(value: Bool, index: Int) {
        sendRP[index] = value
    }
}
