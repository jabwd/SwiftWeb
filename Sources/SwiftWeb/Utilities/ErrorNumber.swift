//
//  ErrorNumber.swift
//  SwiftWebPackageDescription
//
//  Created by Antwan van Houdt on 25/02/2018.
//
#if os(Linux)
	import Glibc
#else
	import Darwin
	import CoreFoundation
#endif

public enum ErrorNumber: Int32 {
	case tryAgain = 35 // EWOULDBLOCK, EAGAIN
	case badFileDescriptor = 9
	case fault = 14 // Outside of your address space
	case interrupt = 4 // Interrupted by a signal
	case invalidInput = 22 // FD not available for reading
	case io = 5
	case isDirectory = 21
	
	static func current() -> ErrorNumber? {
		let errorNumber = ErrorNumber(rawValue: errno)
		return errorNumber
	}
}
