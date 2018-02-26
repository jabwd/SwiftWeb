import Dispatch

public class Server: SocketDelegate {
	public let service: Service
	
    private let syncQueue:       DispatchQueue
    private let listeningSocket: Socket
	
	private var sockets: [Socket]
	
	internal var nextIndex: Int {
		return sockets.count
	}
    
	public init(port: UInt16, service: Service) {
		self.service  = service
        syncQueue     = DispatchQueue(label: "synchronizationQueue")
		sockets       = []
		
		// Technically this should never be needed but I do want to reach
		// C10K with this code, so I might even increase it later!
		sockets.reserveCapacity(1024)
		
		listeningSocket = Socket(listen: port, index: 0)
		listeningSocket.server = self
		listeningSocket.delegate = self
    }
	
	deinit {
		
	}
	
	// MARK: Listening for connections
	
	public var socketShouldAcceptNewClients: Bool {
		return true
	}
	
	public func socketDidAcceptNew(client: Socket, listeningSocket: Socket) {
		client.delegate = service.newSocketDelegate()
		client.server = self
		sockets.append(client)
		print("[\(type(of: self))] New socket \(client.socketIndex)")
	}
	
	// MARK: - Managing connections
	
	internal func close(socket: Socket) {
		syncQueue.sync {
			socket.delegate = nil
			socket.server = nil
			sockets.remove(at: socket.socketIndex)
			print("[\(type(of: self))] Connection closed \(socket.socketIndex), open: \(sockets.count)")
		}
	}
}
