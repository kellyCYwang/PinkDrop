import ActivityKit
import Foundation

struct MetronomeAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var bpm: Int
        var beatsPerMeasure: Int
        var subdivision: Int
        var isPlaying: Bool
        var tempoMarking: String
    }
}
