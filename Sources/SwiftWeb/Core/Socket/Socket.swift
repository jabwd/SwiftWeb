//
//  Socket.swift
//  SwiftWebPackageDescription
//
//  Created by Antwan van Houdt on 20/02/2018.
//
#if os(Linux)
    import Glibc
#else
    import Darwin
    import CoreFoundation
#endif
import SwiftEvent

public enum SocketError: Error {
	
}

public enum SocketType {
	case listening
	case client
}

public class Socket {
    public let port: UInt16
    
    weak var delegate: SocketDelegate?
	
	private var dispatchSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = 0
	private var readAvailableEvent:  Event? = nil
	private var writeAvailableEvent: Event? = nil
	private let socketType: SocketType
    
    init(listen port: UInt16, delegate: SocketDelegate? = nil) {
        self.port = port
        self.delegate = delegate
		self.socketType = .listening
		
		setupForListening()
    }
    
    init(host: String, port: UInt16, delegate: SocketDelegate? = nil) {
        self.port = port
        self.delegate = delegate
		self.socketType = .client
    }
    
    init(fileDescriptor: Int32, delegate: SocketDelegate? = nil) {
        self.port = 0
        self.delegate = delegate
		self.socketType = .client
    }
    
    deinit {
    }
    
    // MARK: - Listening socket
    
    private func setupForListening() -> Void {
        var address        = sockaddr_in()
        address.sin_family = sa_family_t(UInt16(AF_INET))
        #if os(Linux)
            address.sin_port = htons(port)
        #else
            address.sin_port = CFSwapInt16HostToBig(port)
        #endif
        address.sin_addr.s_addr = UInt32(0)
        
        #if os(Linux)
            fileDescriptor = Glibc.socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
        #else
            fileDescriptor = Darwin.socket(AF_INET, SOCK_STREAM, 0)
        #endif
		
		// Allow quick reusage of the local address if applicable
		var option: Int32 = 1
		setsockopt(fileDescriptor, SOL_SOCKET, SO_REUSEADDR, &option, UInt32(MemoryLayout<Int32>.size))
		
		let result = withUnsafePointer(to: &address) {
			$0.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockAddress in
				// Do nothing
				bind(fileDescriptor, sockAddress, UInt32(MemoryLayout<sockaddr_in>.size))
			}
		}
		guard result == 0 else {
			switch(errno) {
			case EBADF:
				print("[\(type(of: self))] Error: Listen socket is a bad file descriptor!")
				return
			case EADDRINUSE:
				print("[\(type(of: self))] Error: address in use, cannot bind")
				return
			case EINVAL:
				print("[\(type(of: self))] Error: socket is already bound!")
				return
			default:
				print("[\(type(of: self))] Error: socket is already bound!")
				return
			}
		}
		guard listen(fileDescriptor, 0) == 0 else {
			print("[\(type(of: self))] Error: Cannot listen on port: \(port)")
			return
		}
		print("[\(type(of: self))] Bound on port \(port)")
		
		makeNonBlocking(fd: fileDescriptor)
		readAvailableEvent = Event(types: [.read, .persistent], fd: fileDescriptor, handler: self)
		if let ev = readAvailableEvent {
			EventManager.shared.register(event: ev)
		}
    }
	
	// MARK: - Client socket
	
	private func setupAsClient() {
		makeNonBlocking(fd: fileDescriptor)
		
		readAvailableEvent  = Event(types: [.read, .persistent], fd: fileDescriptor, handler: self)
		
		// Write events aren't made persistent as it'll keep on spamming while writing is technically
		// possible. Therefore we manually add write events, or more precisely enable them
		// when we have data that needs to be written in our buffer.
		writeAvailableEvent = Event(types: [.write], fd: fileDescriptor, handler: self)
	}
	
	// MARK: -
	
	func disconnect() {
		close(fileDescriptor)
		delegate = nil
	}
}

extension Socket: EventHandler {
	public func readEvent() {
		guard socketType == .listening else {
			// handle data to read
			return
		}
		guard delegate?.socketShouldAcceptNewClients == true else {
			disconnect()
			return
		}
		
		let newClient = accept(fileDescriptor, nil, nil)
		guard newClient != -1 else {
			print("[\(type(of: self))] Unable to accept new socket \(errno)")
			disconnect()
			return
		}
		
		switch(errno) {
		case EMFILE, ENFILE:
			print("[\(type(of: self))] Maximum number of allowed connections reached. Reconfigure your kernel")
			return
		case EBADF:
			print("[\(type(of: self))] Bad file descriptor, cannot accept new client")
			return
		default:
			let newClient = Socket(fileDescriptor: newClient)
			delegate?.socketDidAcceptNew(client: newClient, listeningSocket: self)
			return
		}
	}
	
	public func writeEvent() {
		guard socketType == .client else {
			return
		}
		
		print("Writing is available.")
	}
}
