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

public class Socket {
    public let port: UInt16
    
    let delegate: SocketDelegate?
    
    private var fileDescriptor: Int32 = 0
    
    init(listen port: UInt16, delegate: SocketListeningDelegate) {
        self.port = port
        self.delegate = delegate
    }
    
    init(host: String, port: UInt16, delegate: SocketClientDelegate) {
        self.port = port
        self.delegate = delegate
    }
    
    init(fileDescriptor: Int32, delegate: SocketClientDelegate) {
        self.port = 0
        self.delegate = delegate
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
    }
}
