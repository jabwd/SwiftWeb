import SwiftEvent
import Darwin

let server = Server(port: 2553, service: HTTPService())

SwiftRunloop.start()
