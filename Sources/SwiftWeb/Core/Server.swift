import Dispatch

public class Server {
    
    private let dispatchGroup:   DispatchGroup
    private let syncQueue:       DispatchQueue
    private let listeningSocket: Socket
    
    public init(port: UInt16) {
        dispatchGroup = DispatchGroup()
        syncQueue     = DispatchQueue(label: "synchronizationQueue")
        
        listeningSocket = Socket(listen: port)
    }
}
