//
//  SocketDelegate.swift
//  SwiftWebPackageDescription
//
//  Created by Antwan van Houdt on 20/02/2018.
//

public protocol SocketDelegate: class {
    // MARK: - General
	
	func socketWillConnect(_ socket: Socket)
	func socketDidConnect(_ socket: Socket)
	func socketWillDisconnect(_ socket: Socket)
	func socketDidDisconnect(_ socket: Socket)
    
    // MARK: - Listening socket
    
	func socketDidAcceptNew(client: Socket, listeningSocket: Socket) -> Void
	var socketShouldAcceptNewClients: Bool { get }
    
    // MARK: - Client socket
	
	func socketDidRead(bytes: [UInt8], socket: Socket) -> Void
	func socketDidFail(error: SocketError, socket: Socket) -> Void
}

// MARK: - Optional methods

public extension SocketDelegate {
	
	func socketWillConnect(_ socket: Socket) { }
	func socketDidConnect(_ socket: Socket) { }
	func socketWillDisconnect(_ socket: Socket) {}
	func socketDidDisconnect(_ socket: Socket) {}
	
	// MARK: - Listening socket
	
	func socketDidAcceptNew(client: Socket, listeningSocket: Socket) -> Void { }
	
	var socketShouldAcceptNewClients: Bool { return false }
	
	// MARK: - Client socket
	
	func socketDidRead(bytes: [UInt8], socket: Socket) -> Void { }
	func socketDidFail(error: SocketError, socket: Socket) -> Void { }
}
