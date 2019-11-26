//
//  logger.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation

enum LogLevel: String {
    case info = "INFO"
    case debug = "DEBUG"
    case verbose = "VERBOSE"
    case warning = "WARNING"
    case error = "ERROR"
}

func Log<T>(_ object: @autoclosure () -> T, _ category: LogLevel = .debug, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
    #if DEBUG
    let objValue = object()
    var stringRepresentation: String = ""
//    
    if let value = objValue as? CustomStringConvertible {
        stringRepresentation = value.description
    }
    
    let fileURL = URL(fileURLWithPath: file).lastPathComponent
    let queue = "[" + (Thread.isMainThread ? "Main" : "BG") + "]"
    
    print("\(Date().toString(format: "yyyy-mm-dd HH:mm:ss")) - <\(queue) \(fileURL) \(function) [Line: \(line)]\n" + stringRepresentation)
    #endif
}

extension String {
    func log(_ file: String = #file, _ function: String = #function, line: Int = #line) {
        Log("\(self)", .debug, file, function, line)
    }
}
