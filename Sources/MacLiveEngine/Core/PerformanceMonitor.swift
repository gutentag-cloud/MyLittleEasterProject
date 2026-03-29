import Foundation
import Combine

/// Tracks FPS, CPU, and memory usage.
final class PerformanceMonitor: ObservableObject {
    
    @Published var currentFPS: Double = 0
    @Published var cpuUsage: Double = 0
    @Published var memoryUsageMB: Double = 0
    @Published var gpuUsage: Double = 0
    
    private var frameCount: Int = 0
    private var lastFPSTime: CFTimeInterval = 0
    private var timer: Timer?
    private var displayLink: CVDisplayLink?
    
    func start() {
        lastFPSTime = CACurrentMediaTime()
        
        // Sample system stats every 2 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.sampleSystemStats()
        }
        
        // Use a display link to count frames
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        if let link = displayLink {
            CVDisplayLinkSetOutputCallback(link, { (_, _, _, _, _, userInfo) -> CVReturn in
                let monitor = Unmanaged<PerformanceMonitor>.fromOpaque(userInfo!).takeUnretainedValue()
                monitor.frameCount += 1
                return kCVReturnSuccess
            }, Unmanaged.passUnretained(self).toOpaque())
            CVDisplayLinkStart(link)
        }
    }
    
    func pause() {
        if let link = displayLink { CVDisplayLinkStop(link) }
    }
    
    func resume() {
        if let link = displayLink { CVDisplayLinkStart(link) }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        if let link = displayLink {
            CVDisplayLinkStop(link)
        }
        displayLink = nil
    }
    
    func tick() {
        frameCount += 1
    }
    
    private func sampleSystemStats() {
        let now = CACurrentMediaTime()
        let elapsed = now - lastFPSTime
        if elapsed > 0 {
            currentFPS = Double(frameCount) / elapsed
        }
        frameCount = 0
        lastFPSTime = now
        
        cpuUsage = measureCPU()
        memoryUsageMB = measureMemory()
    }
    
    private func measureCPU() -> Double {
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0
        let result = task_threads(mach_task_self_, &threadList, &threadCount)
        guard result == KERN_SUCCESS, let threads = threadList else { return 0 }
        
        var totalCPU: Double = 0
        let threadBasicInfoCount = mach_msg_type_number_t(MemoryLayout<thread_basic_info_data_t>.size / MemoryLayout<natural_t>.size)
        
        for i in 0..<Int(threadCount) {
            var info = thread_basic_info()
            var count = threadBasicInfoCount
            let kr = withUnsafeMutablePointer(to: &info) { ptr in
                ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), intPtr, &count)
                }
            }
            if kr == KERN_SUCCESS && info.flags & TH_FLAGS_IDLE == 0 {
                totalCPU += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100
            }
        }
        
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(threadCount) * vm_size_t(MemoryLayout<thread_t>.size))
        return totalCPU
    }
    private func measureMemory() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kr = withUnsafeMutablePointer(to: &info) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), intPtr, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return 0 }
        return Double(info.resident_size) / (1024 * 1024)
    }
}
