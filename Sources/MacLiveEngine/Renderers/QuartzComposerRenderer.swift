import AppKit
import Quartz

/// Renders Quartz Composer (.qtz) compositions.
final class QuartzComposerRenderer: WallpaperRenderer {
    
    let targetView: NSView
    private let configuration: Configuration
    private var qcView: QCView?
    
    init(targetView: NSView, configuration: Configuration) {
        self.targetView = targetView
        self.configuration = configuration
    }
    
    func load(url: URL) {
        cleanup()
        
        let qcView = QCView(frame: targetView.bounds)
        qcView.autoresizingMask = [.width, .height]
        
        if let composition = QCComposition(file: url.path) {
            qcView.loadComposition(composition)
        } else {
            qcView.load(url.path)
        }
        
        qcView.maxRenderingFrameRate = Float(configuration.targetFPS)
        
        targetView.subviews.forEach { $0.removeFromSuperview() }
        targetView.addSubview(qcView)
        self.qcView = qcView
        
        Logger.shared.info("Quartz Composer composition loaded")
    }
    
    func start() {
        qcView?.startRendering()
    }
    
    func pause() {
        qcView?.pauseRendering()
    }
    
    func resume() {
        qcView?.resumeRendering()
    }
    
    func stop() {
        cleanup()
    }
    
    func setTargetFPS(_ fps: Int) {
        qcView?.maxRenderingFrameRate = Float(fps)
    }
    
    func receiveAudioSpectrum(_ spectrum: AudioSpectrum) {
        // Pass audio data as input to the composition
        qcView?.setValue(NSNumber(value: spectrum.overallLevel), forInputKey: "audioLevel")
        qcView?.setValue(NSNumber(value: spectrum.bass), forInputKey: "audioBass")
        qcView?.setValue(NSNumber(value: spectrum.mid), forInputKey: "audioMid")
        qcView?.setValue(NSNumber(value: spectrum.treble), forInputKey: "audioTreble")
    }
    
    private func cleanup() {
        qcView?.stopRendering()
        qcView?.removeFromSuperview()
        qcView = nil
    }
}
