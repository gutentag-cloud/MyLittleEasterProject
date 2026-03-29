import Foundation
import IOKit.ps
import Combine

/// Monitors battery state and AC power status.
final class BatteryMonitor: ObservableObject {
    
    @Published var isOnBattery: Bool = false
    @Published var batteryLevel: Double = 100
    @Published var isCharging: Bool = false
    
    private var timer: Timer?
    
    func start() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.update()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func update() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return
        }
        
        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            
            if let powerSource = info[kIOPSPowerSourceStateKey] as? String {
                isOnBattery = powerSource == kIOPSBatteryPowerValue
            }
            
            if let capacity = info[kIOPSCurrentCapacityKey] as? Int,
               let maxCapacity = info[kIOPSMaxCapacityKey] as? Int, maxCapacity > 0 {
                batteryLevel = Double(capacity) / Double(maxCapacity) * 100
            }
            
            if let charging = info[kIOPSIsChargingKey] as? Bool {
                isCharging = charging
            }
        }
    }
}
