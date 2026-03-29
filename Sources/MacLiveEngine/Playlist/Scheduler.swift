import Foundation
import Combine

/// Switches wallpapers based on time of day.
final class Scheduler: ObservableObject {
    
    @Published var activeWallpaperURL: URL?
    @Published var isDaytime: Bool = true
    
    private let configuration: Configuration
    private var timer: Timer?
    
    init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    func start() {
        evaluate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.evaluate()
        }
        Logger.shared.info("Scheduler started (sunrise: \(configuration.sunriseHour)h, sunset: \(configuration.sunsetHour)h)")
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func evaluate() {
        let hour = Calendar.current.component(.hour, from: Date())
        let newIsDaytime = hour >= configuration.sunriseHour && hour < configuration.sunsetHour
        
        if newIsDaytime != isDaytime || activeWallpaperURL == nil {
            isDaytime = newIsDaytime
            if isDaytime {
                if let url = configuration.dayWallpaperURL {
                    activeWallpaperURL = url
                    Logger.shared.info("Scheduler: switching to day wallpaper")
                }
            } else {
                if let url = configuration.nightWallpaperURL {
                    activeWallpaperURL = url
                    Logger.shared.info("Scheduler: switching to night wallpaper")
                }
            }
        }
    }
}
