//
//  Connection.swift
//  SwiftWebPackageDescription
//
//  Created by Antwan van Houdt on 20/02/2018.
//
import Dispatch

public class Connection: SocketDelegate {
    internal let server:          Server
	internal let socket:          Socket
    internal let connectionIndex: Int
	
	internal let workQueue: DispatchQueue
    
	internal init(server: Server, socket: Socket, index: Int) {
		self.workQueue       = DispatchQueue(label: "\(index).connection.queue")
        self.server          = server
        self.connectionIndex = index
		self.socket          = socket
    }
    
    public func send(bytes: [UInt8]) -> Void {
        
    }
}
