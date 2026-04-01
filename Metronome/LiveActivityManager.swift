import ActivityKit
import Foundation

final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<MetronomeAttributes>?

    private init() {}

    func startActivity(bpm: Int, beatsPerMeasure: Int, subdivision: Int, tempoMarking: String) {
        // End any existing activity first
        Task { await endActivity() }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = MetronomeAttributes.ContentState(
            bpm: bpm,
            beatsPerMeasure: beatsPerMeasure,
            subdivision: subdivision,
            isPlaying: true,
            tempoMarking: tempoMarking
        )

        let content = ActivityContent(state: state, staleDate: nil)

        do {
            currentActivity = try Activity.request(
                attributes: MetronomeAttributes(),
                content: content,
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    func updateActivity(bpm: Int, beatsPerMeasure: Int, subdivision: Int, isPlaying: Bool, tempoMarking: String) {
        guard let activity = currentActivity else { return }

        let state = MetronomeAttributes.ContentState(
            bpm: bpm,
            beatsPerMeasure: beatsPerMeasure,
            subdivision: subdivision,
            isPlaying: isPlaying,
            tempoMarking: tempoMarking
        )

        let content = ActivityContent(state: state, staleDate: nil)

        Task {
            await activity.update(content)
        }
    }

    func endActivity() async {
        guard let activity = currentActivity else { return }
        let finalState = MetronomeAttributes.ContentState(
            bpm: 0,
            beatsPerMeasure: 4,
            subdivision: 1,
            isPlaying: false,
            tempoMarking: ""
        )
        let content = ActivityContent(state: finalState, staleDate: nil)
        await activity.end(content, dismissalPolicy: .immediate)
        currentActivity = nil
    }
}
