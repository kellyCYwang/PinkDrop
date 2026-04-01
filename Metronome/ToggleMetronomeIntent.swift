import AppIntents
import ActivityKit

struct ToggleMetronomeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Toggle Metronome"
    static var description: IntentDescription = "Start or stop the metronome"

    func perform() async throws -> some IntentResult {
        let engine = AudioEngine.shared

        await MainActor.run {
            if engine.isPlaying {
                engine.stop()
                Task { await LiveActivityManager.shared.endActivity() }
            } else {
                engine.start()
                LiveActivityManager.shared.startActivity(
                    bpm: Int(engine.bpm),
                    beatsPerMeasure: engine.beatsPerMeasure,
                    subdivision: engine.subdivision,
                    tempoMarking: tempoMarking(for: Int(engine.bpm))
                )
            }
        }

        return .result()
    }

    private func tempoMarking(for bpm: Int) -> String {
        switch bpm {
        case 0..<40: return "Grave"
        case 40..<55: return "Largo"
        case 55..<65: return "Lento"
        case 65..<73: return "Adagio"
        case 73..<78: return "Andante"
        case 78..<85: return "Andantino"
        case 85..<98: return "Moderato"
        case 98..<109: return "Allegretto"
        case 109..<132: return "Allegro"
        case 132..<140: return "Vivace"
        case 140..<178: return "Presto"
        default: return "Prestissimo"
        }
    }
}
