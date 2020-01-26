//
//  File.swift
//  TestClient
//
//  Created by Patrick Wang on 12/7/19.
//  Copyright © 2019 PatrickWang. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class UDPSocket: NSObject, GCDAsyncUdpSocketDelegate {
    var host: String!
    var port: UInt16!
    var dataString = ""
    var socket: GCDAsyncUdpSocket!
    
    init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }
    
    func setupConnection(){
        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.global(qos: .utility))
        do { try socket.connect(toHost: host, onPort: port) } catch { print("connectino failed") }
        do { try socket.beginReceiving() } catch { print("begin receiving failed") }
    }

    func send(message:String){
        print("wrote \(message)")
        let data = message.data(using: String.Encoding.utf8)
        socket.send(data!, withTimeout: 2, tag: 0)
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        if let dataString = String(data: data, encoding: .utf8) {
            self.dataString += dataString
        }
    }
    
    func popDataString() -> String {
        let retString = self.dataString
        self.dataString = ""
        return retString
    }
}
