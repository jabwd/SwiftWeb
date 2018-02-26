//
//  HTTPService.swift
//  SwiftWeb
//
//  Created by Antwan van Houdt on 26/02/2018.
//
import Foundation

class HTTPService: Service {
	init() {
		
	}
	
	func newSocketDelegate() -> SocketDelegate {
		return self
	}
}

extension HTTPService: SocketDelegate {
	func socketDidRead(bytes: [UInt8], socket: Socket) {
		guard let string = String(bytes: bytes, encoding: .utf8) else {
			return
		}
		let content = "<html><body><h1>Hello from swift</h1></body></html>"
		let response = "HTTP/1.1 200 OK\r\nServer: Pwngine (Swift)\r\nLast-Modified: Mon, 26 Feb 2018 21:22:00 GMT\r\nContent-Length: \(content.utf8.count)\r\nContent-Type: text/html\r\nConnection: Closed\r\n\r\n\(content)"
		print("String: \(string)")
		print("Response: \n \(response)")
		socket.send(bytes: Array(response.utf8), tag: 0)
	}
}
