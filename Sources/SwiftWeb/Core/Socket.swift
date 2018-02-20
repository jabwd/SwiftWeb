//
//  Socket.swift
//  SwiftWebPackageDescription
//
//  Created by Antwan van Houdt on 20/02/2018.
//

public class Socket {
    public let port: UInt16
    
    init(listen port: UInt16) {
        self.port = port
    }
}
