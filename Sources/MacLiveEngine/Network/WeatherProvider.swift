import Foundation
import Combine
import CoreLocation

/// Fetches current weather conditions and maps them to wallpaper presets.
final class WeatherProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var currentCondition: WeatherCondition = .clear
    @Published var temperature: Double = 20
    @Published var isDaytime: Bool = true
    
    private let locationManager = CLLocationManager()
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    enum WeatherCondition: String, Codable {
        case clear, cloudy, rain, snow, thunderstorm, fog, wind
        
        /// Suggests a particle preset for this weather.
        var suggestedParticlePreset: String {
            switch self {
            case .clear: return "starfield"
            case .cloudy: return "fireflies"
            case .rain: return "rain"
            case .snow: return "snow"
            case .thunderstorm: return "rain"
            case .fog: return "fireflies"
            case .wind: return "starfield"
            }
        }
        
        /// Suggests a shader preset for this weather.
        var suggestedShaderPreset: String {
            switch self {
            case .clear: return "plasma"
            case .rain: return "rain_drops"
            case .snow: return "snow_fall"
            default: return "flow_field"
            }
        }
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func start() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Refresh every 30 minutes
        timer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            self?.locationManager.requestLocation()
        }
    }
    
    func stop() {
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        fetchWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.shared.warning("Location error: \(error.localizedDescription)")
    }
    
    private func fetchWeather(latitude: Double, longitude: Double) {
        // Using Open-Meteo (free, no API key)
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current_weather=true"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else { return }
            
            struct WeatherResponse: Decodable {
                struct CurrentWeather: Decodable {
                    let temperature: Double
                    let weathercode: Int
                    let is_day: Int
                }
                let current_weather: CurrentWeather
            }
            
            guard let response = try? JSONDecoder().decode(WeatherResponse.self, from: data) else { return }
            
            let condition: WeatherCondition
            switch response.current_weather.weathercode {
            case 0, 1:          condition = .clear
            case 2, 3:          condition = .cloudy
            case 45, 48:        condition = .fog
            case 51...67:       condition = .rain
            case 71...77:       condition = .snow
            case 80...86:       condition = .rain
            case 95...99:       condition = .thunderstorm
            default:            condition = .clear
            }
            
            DispatchQueue.main.async {
                self?.currentCondition = condition
                self?.temperature = response.current_weather.temperature
                self?.isDaytime = response.current_weather.is_day == 1
                Logger.shared.info("Weather updated: \(condition.rawValue), \(response.current_weather.temperature)°C")
            }
        }.resume()
    }
}
