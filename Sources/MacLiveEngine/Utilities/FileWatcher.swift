import Foundation

/// Watches a file or directory for changes and calls a handler.
final class FileWatcher {
    
    private var source: DispatchSourceFileSystemObject?
    private let path: String
    private let handler: () -> Void
    
    init(path: String, handler: @escaping () -> Void) {
        self.path = path
        self.handler = handler
    }
    
    func start() {
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else {
            Logger.shared.error("FileWatcher: cannot open \(path)")
            return
        }
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete, .extend],
            queue: .main
        )
        
        source.setEventHandler { [weak self] in
            self?.handler()
        }
        
        source.setCancelHandler {
            close(fd)
        }
        
        source.resume()
        self.source = source
        
        Logger.shared.info("FileWatcher: watching \(path)")
    }
    
    func stop() {
        source?.cancel()
        source = nil
    }
    
    deinit {
        stop()
    }
}
