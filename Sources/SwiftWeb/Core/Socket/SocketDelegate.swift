//
//  SocketDelegate.swift
//  SwiftWebPackageDescription
//
//  Created by Antwan van Houdt on 20/02/2018.
//

protocol SocketDelegate {
    // MARK: - General
    
    // MARK: - Listening socket
    
    func didAcceptNew(client: Socket) -> Void
    
    func socketShouldAcceptNewClients() -> Bool
    
    // MARK: - Client socket
}

// MARK: - Optional methods

extension SocketDelegate {
    
}
