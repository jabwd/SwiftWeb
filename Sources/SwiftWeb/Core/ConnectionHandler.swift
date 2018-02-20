//
//  ConnectionHandler.swift
//  SwiftWebPackageDescription
//
//  Created by Antwan van Houdt on 20/02/2018.
//

public protocol ConnectionHandler {
    func didReceiveData(_ bytes: [UInt8]) -> Void
}
