//
//  File.swift
//  SwiftWebPackageDescription
//
//  Created by Antwan van Houdt on 26/02/2018.
//

public protocol Service {
	func newSocketDelegate() -> SocketDelegate
}
