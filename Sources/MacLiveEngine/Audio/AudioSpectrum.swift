import Foundation

/// Holds processed audio frequency data.
struct AudioSpectrum: Codable {
    var bands: [Float]
    var bass: Float
    var mid: Float
    var treble: Float
    var overallLevel: Float
    
    init(bands: [Float] = [], bass: Float = 0, mid: Float = 0, treble: Float = 0, overallLevel: Float = 0) {
        self.bands = bands
        self.bass = bass
        self.mid = mid
        self.treble = treble
        self.overallLevel = overallLevel
    }
}
