import AVFoundation
import Accelerate
import Combine

/// Captures system audio (or microphone) and computes a frequency spectrum.
final class AudioEngine: ObservableObject {
    
    @Published var spectrum = AudioSpectrum()
    @Published var isRunning = false
    
    private var audioEngine: AVAudioEngine?
    private var fftSetup: vDSP_DFT_Setup?
    private let fftSize = 1024
    private var smoothedMagnitudes: [Float] = []
    private let smoothing: Float = 0.7
    
    func start() {
        guard !isRunning else { return }
        
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        let bufferSize = AVAudioFrameCount(fftSize)
        smoothedMagnitudes = [Float](repeating: 0, count: fftSize / 2)
        
        fftSetup = vDSP_DFT_zop_CreateSetup(nil, vDSP_Length(fftSize), .FORWARD)
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try engine.start()
            self.audioEngine = engine
            isRunning = true
            Logger.shared.info("Audio engine started")
        } catch {
            Logger.shared.error("Failed to start audio engine: \(error)")
        }
    }
    
    func stop() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isRunning = false
        Logger.shared.info("Audio engine stopped")
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0],
              let fftSetup = fftSetup else { return }
        
        let frameCount = Int(buffer.frameLength)
        let count = min(frameCount, fftSize)
        
        // Apply Hanning window
        var windowedData = [Float](repeating: 0, count: fftSize)
        var window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        vDSP_vmul(channelData, 1, &window, 1, &windowedData, 1, vDSP_Length(count))
        
        // FFT
        var realIn = [Float](repeating: 0, count: fftSize)
        var imagIn = [Float](repeating: 0, count: fftSize)
        var realOut = [Float](repeating: 0, count: fftSize)
        var imagOut = [Float](repeating: 0, count: fftSize)
        
        realIn = windowedData
        
        vDSP_DFT_Execute(fftSetup, &realIn, &imagIn, &realOut, &imagOut)
        
        // Compute magnitudes
        var magnitudes = [Float](repeating: 0, count: fftSize / 2)
        for i in 0..<fftSize / 2 {
            magnitudes[i] = sqrt(realOut[i] * realOut[i] + imagOut[i] * imagOut[i])
        }
        
        // Convert to dB and normalize
        var logMagnitudes = [Float](repeating: 0, count: fftSize / 2)
        var one: Float = 1.0
        vDSP_vdbcon(&magnitudes, 1, &one, &logMagnitudes, 1, vDSP_Length(fftSize / 2), 0)
        
        // Normalize to 0-1 range
        var minVal: Float = 0
        var maxVal: Float = 0
        vDSP_minv(&logMagnitudes, 1, &minVal, vDSP_Length(fftSize / 2))
        vDSP_maxv(&logMagnitudes, 1, &maxVal, vDSP_Length(fftSize / 2))
        
        let range = maxVal - minVal
        if range > 0 {
            for i in 0..<fftSize / 2 {
                logMagnitudes[i] = (logMagnitudes[i] - minVal) / range
            }
        }
        
        // Smooth
        for i in 0..<fftSize / 2 {
            smoothedMagnitudes[i] = smoothing * smoothedMagnitudes[i] + (1 - smoothing) * logMagnitudes[i]
        }
        
        // Build spectrum
        let halfCount = fftSize / 2
        let bassRange = 0..<(halfCount / 8)
        let midRange = (halfCount / 8)..<(halfCount / 2)
        let trebleRange = (halfCount / 2)..<halfCount
        
        let bass = bassRange.isEmpty ? 0 : bassRange.map { smoothedMagnitudes[$0] }.reduce(0, +) / Float(bassRange.count)
        let mid = midRange.isEmpty ? 0 : midRange.map { smoothedMagnitudes[$0] }.reduce(0, +) / Float(midRange.count)
        let treble = trebleRange.isEmpty ? 0 : trebleRange.map { smoothedMagnitudes[$0] }.reduce(0, +) / Float(trebleRange.count)
        let overall = (bass + mid + treble) / 3.0
        
        let result = AudioSpectrum(
            bands: Array(smoothedMagnitudes.prefix(64)),
            bass: bass,
            mid: mid,
            treble: treble,
            overallLevel: overall
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.spectrum = result
        }
    }
}
