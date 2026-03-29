import Foundation
import Combine

/// Downloads wallpaper files from URLs with progress tracking.
final class WallpaperDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    
    @Published var progress: Double = 0
    @Published var isDownloading: Bool = false
    @Published var lastDownloadedURL: URL?
    @Published var error: String?
    
    private var session: URLSession!
    private var continuation: CheckedContinuation<URL, Error>?
    
    static let downloadsDirectory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("MacLiveEngine/Downloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }
    
    /// Download a wallpaper from a URL, returns the local file URL.
    func download(from url: URL) async throws -> URL {
        isDownloading = true
        progress = 0
        error = nil
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            session.downloadTask(with: url).resume()
        }
    }
    
    /// Synchronous convenience — starts download and calls completion.
    func download(from url: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        Task {
            do {
                let localURL = try await download(from: url)
                completion(.success(localURL))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        let filename = downloadTask.originalRequest?.url?.lastPathComponent ?? "wallpaper"
        let dest = Self.downloadsDirectory.appendingPathComponent(filename)
        
        do {
            // Remove existing file if needed
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.moveItem(at: location, to: dest)
            
            isDownloading = false
            lastDownloadedURL = dest
            continuation?.resume(returning: dest)
            continuation = nil
            
            Logger.shared.info("Downloaded wallpaper: \(filename)")
        } catch {
            self.error = error.localizedDescription
            isDownloading = false
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            self.error = error.localizedDescription
            isDownloading = false
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}
