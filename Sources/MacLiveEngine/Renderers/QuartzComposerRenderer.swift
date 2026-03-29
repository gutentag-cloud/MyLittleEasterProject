import AppKit
import Quartz

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
        let view = QCView(frame: targetView.bounds)
        view.autoresizingMask = [.width, .height]
        
        // Correct Modern API calls
        if let composition = QCComposition(file: url.path) {
            view.load(composition)
        }
        
        view.setMaxRenderingFrameRate(Float(configuration.targetFPS))
        
        targetView.subviews.forEach { $0.removeFromSuperview() }
        targetView.addSubview(view)
        self.qcView = view
    }
    
    func start() { qcView?.startRendering() }
    func pause() { qcView?.pauseRendering() }
    func resume() { qcView?.resumeRendering() }
    func stop() { cleanup() }
    
    func setTargetFPS(_ fps: Int) {
        qcView?.setMaxRenderingFrameRate(Float(fps))
    }
    
    func receiveAudioSpectrum(_ spectrum: AudioSpectrum) {
        qcView?.setValue(spectrum.overallLevel, forInputKey: "audioLevel")
        qcView?.setValue(spectrum.bass, forInputKey: "audioBass")
    }
    
    private func cleanup() {
        qcView?.stopRendering()
        qcView?.removeFromSuperview()
        qcView = nil
    }
}
