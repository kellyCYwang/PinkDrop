import AppIntents
import ActivityKit

struct ToggleMetronomeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Toggle Metronome"
    static var description: IntentDescription = "Start or stop the metronome"

    func perform() async throws -> some IntentResult {
        // Execution happens in the main app process
        return .result()
    }
}
