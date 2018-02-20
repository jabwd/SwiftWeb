//
//  SocketDelegate.swift
//  SwiftWebPackageDescription
//
//  Created by Antwan van Houdt on 20/02/2018.
//

protocol SocketDelegate: class {
    // MARK: - General
    
    // MARK: - Listening socket
    
	func socketDidAcceptNew(client: Socket, listeningSocket: Socket) -> Void
    
	var socketShouldAcceptNewClients: Bool { get }
    
    // MARK: - Client socket
	
	func socketDidRead(bytes: [UInt8], socket: Socket) -> Void
	func socketDidFail(error: SocketError, socket: Socket) -> Void
	func socketDidWrite(dataWithTag tag: Int) -> Void
	func socketWriteFailed(dataWithTag tag: Int) -> Void
}

// MARK: - Optional methods

extension SocketDelegate {
	
	// MARK: - Listening socket
	
	func socketDidAcceptNew(client: Socket, listeningSocket: Socket) -> Void { }
	
	var socketShouldAcceptNewClients: Bool {
		return false
	}
	
	// MARK: - Client socket
	
	func socketDidRead(bytes: [UInt8], socket: Socket) -> Void { }
	func socketDidFail(error: SocketError, socket: Socket) -> Void { }
	func socketDidWrite(dataWithTag tag: Int) -> Void { }
	func socketWriteFailed(dataWithTag tag: Int) -> Void { }
}
