//
//  Connection.swift
//  SwiftWebPackageDescription
//
//  Created by Antwan van Houdt on 20/02/2018.
//

public class Connection {
    internal let server:          Server
    internal let connectionIndex: Int
    
    internal init(server: Server, index: Int) {
        self.server          = server
        self.connectionIndex = index
    }
    
    public func send(bytes: [UInt8]) -> Void {
        
    }
}
