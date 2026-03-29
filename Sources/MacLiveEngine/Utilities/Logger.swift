import Foundation
import os

/// Centralized logging with os_log and optional file logging.
final class Logger {
    
    static let shared = Logger()
    
    private let osLog = OSLog(subsystem: "com.macliveengine", category: "general")
    private let fileHandle: FileHandle?
    private let dateFormatter: DateFormatter
    private let queue = DispatchQueue(label: "com.macliveengine.logger", qos: .utility)
    
    enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
    }
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        let logDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("MacLiveEngine/Logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        
        let logFile = logDir.appendingPathComponent("macliveengine.log")
        
        // Rotate log if > 10MB
        if let attrs = try? FileManager.default.attributesOfItem(atPath: logFile.path),
           let size = attrs[.size] as? UInt64, size > 10_000_000 {
            let archive = logDir.appendingPathComponent("macliveengine_prev.log")
            try? FileManager.default.removeItem(at: archive)
            try? FileManager.default.moveItem(at: logFile, to: archive)
        }
        
        FileManager.default.createFile(atPath: logFile.path, contents: nil)
        fileHandle = FileHandle(forWritingAtPath: logFile.path)
        fileHandle?.seekToEndOfFile()
    }
    
    deinit {
        fileHandle?.closeFile()
    }
    
    func debug(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .debug, message: message, file: file, line: line)
    }
    
    func info(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .info, message: message, file: file, line: line)
    }
    
    func warning(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .warning, message: message, file: file, line: line)
    }
    
    func error(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .error, message: message, file: file, line: line)
    }
    
    private func log(level: Level, message: String, file: String, line: Int) {
        let fileName = (file as NSString).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())
        let entry = "[\(timestamp)] [\(level.rawValue)] [\(fileName):\(line)] \(message)"
        
        // os_log
        switch level {
        case .debug: os_log(.debug, log: osLog, "%{public}@", entry)
        case .info: os_log(.info, log: osLog, "%{public}@", entry)
        case .warning: os_log(.default, log: osLog, "%{public}@", entry)
        case .error: os_log(.error, log: osLog, "%{public}@", entry)
        }
        
        // File
        queue.async { [weak self] in
            if let data = (entry + "\n").data(using: .utf8) {
                self?.fileHandle?.write(data)
            }
        }
        
        #if DEBUG
        print(entry)
        #endif
    }
}
