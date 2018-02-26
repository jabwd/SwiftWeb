//
//  Connection.swift
//  SwiftWebPackageDescription
//
//  Created by Antwan van Houdt on 20/02/2018.
//
import Dispatch

public class Connection {
    internal let server:          Server
	internal let socket:          Socket
    internal let connectionIndex: Int
	
	internal let workQueue: DispatchQueue
    
	internal init(server: Server, socket: Socket, index: Int) {
		self.workQueue       = DispatchQueue(label: "\(index).connection.queue")
        self.server          = server
        self.connectionIndex = index
		self.socket          = socket
		
		socket.delegate = self
    }
    
    public func send(bytes: [UInt8]) -> Void {
        
    }
}

extension Connection: SocketDelegate {
	func socketDidRead(bytes: [UInt8], socket: Socket) {
		print("Received bytes: \(bytes)")
	}
	
	func socketDidFail(error: SocketError, socket: Socket) {
		print("Socket error \(error)")
	}
	
	func socketDidWrite(dataWithTag tag: Int) {
		print("Wrote data with tag: \(tag)")
	}
}
