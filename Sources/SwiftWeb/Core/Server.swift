import Dispatch

public class Server: SocketDelegate {
    private let dispatchGroup:   DispatchGroup
    private let syncQueue:       DispatchQueue
    private let listeningSocket: Socket
	
	private var connections: [Connection]
    
    public init(port: UInt16) {
        dispatchGroup = DispatchGroup()
        syncQueue     = DispatchQueue(label: "synchronizationQueue")
		connections   = []
		connections.reserveCapacity(20) // Increase as needed.
		
		listeningSocket = Socket(listen: port)
		listeningSocket.delegate = self
    }
	
	deinit {
		
	}
	
	// MARK: -
	
	var socketShouldAcceptNewClients: Bool {
		return true
	}
	
	func socketDidAcceptNew(client: Socket, listeningSocket: Socket) {
		print("New socket was detected: \(client)")
		
		let newConnection = Connection(server: self, socket: client, index: connections.count)
		connections.append(newConnection)
	}
}
