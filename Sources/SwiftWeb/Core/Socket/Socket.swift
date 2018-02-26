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
import Dispatch

public enum SocketError: Error {
	
}

public enum SocketType {
	case listening
	case client
}

fileprivate struct SendBuffer {
	let data: [UInt8]
	let tag: Int
}

public class Socket {
    public let port: UInt16
	public let socketIndex: Int
	
    weak var delegate: SocketDelegate?
	
	internal weak var server: Server? = nil
	private var dispatchSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = 0
	private var readAvailableEvent:  Event? = nil
	private var writeAvailableEvent: Event? = nil
	private let socketType: SocketType
	private let workQueue: DispatchQueue
	private var sendQueue: [UInt8]
	private var canWrite: Bool = false
    
	init(listen port: UInt16, index: Int, delegate: SocketDelegate? = nil) {
        self.port = port
        self.delegate = delegate
		self.socketType = .listening
		self.socketIndex = index
		self.workQueue = DispatchQueue(label: "\(index).connection.queue")
		self.sendQueue = []
		
		setupForListening()
    }
    
	init(host: String, port: UInt16, index: Int, delegate: SocketDelegate? = nil) {
        self.port = port
        self.delegate = delegate
		self.socketType = .client
		self.socketIndex = index
		self.workQueue = DispatchQueue(label: "\(socketIndex).connection.queue")
		self.sendQueue = []
		
		setupAsClient()
    }
    
	init(fileDescriptor: Int32, index: Int, delegate: SocketDelegate? = nil) {
        self.port = 0
        self.delegate = delegate
		self.socketType = .client
		self.fileDescriptor = fileDescriptor
		self.socketIndex = index
		self.workQueue   = DispatchQueue(label: "\(index).connection.queue")
		self.sendQueue = []
		
		setupAsClient()
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
				bind(fileDescriptor, sockAddress, UInt32(MemoryLayout<sockaddr_in>.size))
			}
		}
		
		// TODO: Replace with ErrorNumber enum
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
		readAvailableEvent  = Event(types: [.read, .persistent], fd: fileDescriptor, handler: self)
		
		// Write events aren't made persistent as it'll keep on spamming while writing is technically
		// possible. Therefore we manually add write events, or more precisely enable them
		// when we have data that needs to be written in our buffer.
		writeAvailableEvent = Event(types: [.write], fd: fileDescriptor, handler: self)
		
		EventManager.shared.register(event: writeAvailableEvent!)
		EventManager.shared.register(event: readAvailableEvent!)
		
		makeNonBlocking(fd: fileDescriptor)
	}
	
	// MARK: -
	
	public func disconnect() {
		workQueue.suspend()
		delegate?.socketWillDisconnect(self)
		
		// Get rid of the libevent hooks
		readAvailableEvent?.handler = nil
		writeAvailableEvent?.handler = nil
		readAvailableEvent?.remove()
		writeAvailableEvent?.remove()
		readAvailableEvent = nil
		writeAvailableEvent = nil
		
		// Forcably shut down the connection, sometimes close() doesn't do
		// all the work for us and the other side notices the disconnect rather late
		shutdown(fileDescriptor, SHUT_RDWR)
		close(fileDescriptor)
		delegate?.socketDidDisconnect(self)
		delegate = nil
		server?.close(socket: self)
	}
	
	// MARK: - Sending data
	
	public func send(bytes: [UInt8], tag: Int) {
		sendQueue += bytes
		checkQueue()
	}
	
	private func checkQueue() {
		guard canWrite == true else {
			writeAvailableEvent?.add()
			return
		}
		guard sendQueue.count > 0 else {
			return
		}
		canWrite = false
		
		let maxSize = 2084
		let bytesToWrite: Int = sendQueue.count > maxSize ? maxSize : sendQueue.count
		let bytesWritten = write(fileDescriptor, &sendQueue, bytesToWrite)
		if bytesWritten < 0 {
			disconnect()
			return
		}
		sendQueue.removeFirst(bytesWritten)
		writeAvailableEvent?.add()
	}
}

extension Socket: EventHandler {
	public func readEvent() {
		if socketType == .listening {
			attemptAcceptNewClient()
			return
		}
		workQueue.async {
			self.readAvailableData()
		}
	}
	
	private func attemptAcceptNewClient() {
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
			let newClient = Socket(fileDescriptor: newClient, index: server?.nextIndex ?? 0)
			delegate?.socketDidAcceptNew(client: newClient, listeningSocket: self)
			return
		}
	}
	
	private func readAvailableData() {
		let buffSize = 1024 // Should be changed to whatever is appropriate for the usage of the socket
		
		// Using UnsafeMutablePointer here crashes for some reason.
		var buffer: [UInt8] = [UInt8](repeating: 0, count: 0)
		var len = 0
		repeat {
			let part = UnsafeMutablePointer<UInt8>.allocate(capacity: buffSize)
			len = read(fileDescriptor, part, buffSize)
			if len > 0 {
				buffer += Array(UnsafeMutableBufferPointer(start: part, count: len))
			}
			part.deallocate(capacity: buffSize)
		} while( len == buffSize );
		if len == 0 {
			disconnect()
			return
		}
		if len == -1 {
			return
		}
		delegate?.socketDidRead(bytes: buffer, socket: self)
	}
	
	public func writeEvent() {
		guard socketType == .client else {
			return
		}
		canWrite = true
		checkQueue()
	}
}
