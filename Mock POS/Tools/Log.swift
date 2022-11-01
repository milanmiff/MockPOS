//
//  Log.swift
//  Mock POS
//
//  Created by Milan Djordjevic on 25/10/2022.
//

import Foundation

enum Log {
    enum LogLevel {
        case info
        case warning
        case error
        
        fileprivate var prefix: String {
            switch self {
            case .info:    return "ℹ️"
            case .warning: return "⚠️"
            case .error:   return "⛔️"
            }
        }
    }
    
    struct Context {
        let file: String
        let function: String
        let line: Int
        var description: String {
            return "\((file as NSString).lastPathComponent):\(line) \(function)"
        }
    }
   
    static func info(_ str: String, shouldLogContext: Bool = true, file: String = #file, function: String = #function, line: Int = #line) {
        let context = Context(file: file, function: function, line: line)
        Log.handleLog(level: .info, str: str.description, shouldLogContext: shouldLogContext, context: context)
    }
    
    static func warning(_ str: String, shouldLogContext: Bool = true, file: String = #file, function: String = #function, line: Int = #line) {
        let context = Context(file: file, function: function, line: line)
        Log.handleLog(level: .warning, str: str.description, shouldLogContext: shouldLogContext, context: context)
    }
    
    static func error(_ str: String, shouldLogContext: Bool = true, file: String = #file, function: String = #function, line: Int = #line) {
        let context = Context(file: file, function: function, line: line)
        Log.handleLog(level: .error, str: str.description, shouldLogContext: shouldLogContext, context: context)
    }
    
    static func removeLog() {
        guard let sharedGroup = UserDefaults(suiteName: "group.me.miff.Mock-POS") else { return }
        sharedGroup.removeObject(forKey: "group.me.miff.Mock-POS.log")
    }

    fileprivate static func handleLog(level: LogLevel, str: String, shouldLogContext: Bool, context: Context) {
        let logComponents = ["[\(level.prefix)]", str]
        
        var fullString = logComponents.joined(separator: " ")
        if shouldLogContext {
            fullString += " ➜ \(context.description)"
        }
        
        #if DEBUG
        print(fullString)
        #endif
        
        guard let sharedGroup = UserDefaults(suiteName: "group.me.miff.Mock-POS") else { return }
        sharedGroup.set(fullString + "\n", forKey: "group.me.miff.Mock-POS.log")
    }
}
