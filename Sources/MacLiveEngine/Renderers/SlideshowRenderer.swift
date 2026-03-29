import AppKit
import Combine

/// Renders a slideshow of images with configurable transitions.
final class SlideshowRenderer: WallpaperRenderer {
    
    let targetView: NSView
    private let configuration: Configuration
    
    private var imageView1: NSImageView!
    private var imageView2: NSImageView!
    private var imageURLs: [URL] = []
    private var currentIndex: Int = 0
    private var timer: Timer?
    private var isTransitioning = false
    
    init(targetView: NSView, configuration: Configuration) {
        self.targetView = targetView
        self.configuration = configuration
        setupViews()
    }
    
    func load(url: URL) {
        if url.hasDirectoryPath {
            loadDirectory(url)
        } else {
            imageURLs = [url]
            showImage(at: 0, animated: false)
        }
    }
    
    func start() {
        guard !imageURLs.isEmpty else { return }
        showImage(at: 0, animated: false)
        startTimer()
        Logger.shared.info("Slideshow started with \(imageURLs.count) images")
    }
    
    func pause() {
        timer?.invalidate()
        timer = nil
    }
    
    func resume() {
        startTimer()
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        imageView1?.removeFromSuperview()
        imageView2?.removeFromSuperview()
    }
    
    func setTargetFPS(_ fps: Int) {}
    
    func setProperty(_ key: String, value: Any) {
        switch key {
        case "interval":
            if let interval = value as? TimeInterval {
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                    self?.nextImage()
                }
            }
        default: break
        }
    }
    
    // MARK: - Private
    
    private func setupViews() {
        targetView.subviews.forEach { $0.removeFromSuperview() }
        
        imageView1 = NSImageView(frame: targetView.bounds)
        imageView1.autoresizingMask = [.width, .height]
        imageView1.imageScaling = .scaleProportionallyUpOrDown
        imageView1.wantsLayer = true
        
        imageView2 = NSImageView(frame: targetView.bounds)
        imageView2.autoresizingMask = [.width, .height]
        imageView2.imageScaling = .scaleProportionallyUpOrDown
        imageView2.wantsLayer = true
        imageView2.alphaValue = 0
        
        targetView.addSubview(imageView1)
        targetView.addSubview(imageView2)
    }
    
    private func loadDirectory(_ url: URL) {
        let extensions = ["png", "jpg", "jpeg", "gif", "heic", "tiff", "webp", "bmp"]
        let fm = FileManager.default
        
        if let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey]) {
            imageURLs = enumerator.compactMap { item -> URL? in
                guard let url = item as? URL else { return nil }
                return extensions.contains(url.pathExtension.lowercased()) ? url : nil
            }
        }
        
        if configuration.playlistShuffle {
            imageURLs.shuffle()
        }
    }
    
    private func startTimer() {
        let interval = configuration.slideshowInterval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.nextImage()
        }
    }
    
    private func nextImage() {
        guard !imageURLs.isEmpty, !isTransitioning else { return }
        currentIndex = (currentIndex + 1) % imageURLs.count
        showImage(at: currentIndex, animated: true)
    }
    
    private func showImage(at index: Int, animated: Bool) {
        guard index < imageURLs.count else { return }
        
        let url = imageURLs[index]
        guard let image = NSImage(contentsOf: url) else { return }
        
        if animated {
            isTransitioning = true
            imageView2.image = image
            
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = configuration.transitionDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                imageView1.animator().alphaValue = 0
                imageView2.animator().alphaValue = 1
            }, completionHandler: { [weak self] in
                guard let self else { return }
                // Swap views
                self.imageView1.image = image
                self.imageView1.alphaValue = 1
                self.imageView2.alphaValue = 0
                self.isTransitioning = false
            })
        } else {
            imageView1.image = image
            imageView1.alphaValue = 1
        }
    }
}
