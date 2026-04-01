import ActivityKit
import AppIntents
import WidgetKit
import SwiftUI

struct MetronomeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MetronomeAttributes.self) { context in
            // Lock Screen / Banner presentation
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Image(systemName: "metronome.fill")
                            .font(.system(size: 20))
                            .foregroundColor(MetronomeTheme.pink)
                        Text(context.state.isPlaying ? "Playing" : "Paused")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(MetronomeTheme.textSecondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(context.state.bpm)")
                            .font(.system(size: 28, weight: .thin, design: .rounded))
                            .foregroundColor(.white)
                        Text("BPM")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(MetronomeTheme.textSecondary)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.tempoMarking)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(MetronomeTheme.pinkLight)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            ForEach(0..<context.state.beatsPerMeasure, id: \.self) { beat in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(beat == 0 ? MetronomeTheme.pink : MetronomeTheme.pinkDark.opacity(0.6))
                                    .frame(height: 6)
                            }
                        }

                        HStack(spacing: 12) {
                            Text("\(context.state.beatsPerMeasure)/4")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(MetronomeTheme.textSecondary)

                            Spacer()

                            Button(intent: ToggleMetronomeIntent()) {
                                Image(systemName: context.state.isPlaying ? "stop.fill" : "play.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(MetronomeTheme.background)
                                    .frame(width: 36, height: 36)
                                    .background(MetronomeTheme.pink)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: "metronome.fill")
                    .foregroundColor(MetronomeTheme.pink)
                    .font(.system(size: 14))
            } compactTrailing: {
                Text("\(context.state.bpm)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(MetronomeTheme.pink)
            } minimal: {
                Image(systemName: "metronome.fill")
                    .foregroundColor(MetronomeTheme.pink)
                    .font(.system(size: 12))
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<MetronomeAttributes>) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "metronome.fill")
                    .font(.system(size: 24))
                    .foregroundColor(MetronomeTheme.pink)
                Text(context.state.isPlaying ? "Playing" : "Paused")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(MetronomeTheme.textSecondary)
            }

            Spacer()

            HStack(spacing: 6) {
                ForEach(0..<context.state.beatsPerMeasure, id: \.self) { beat in
                    Circle()
                        .fill(beat == 0 ? MetronomeTheme.pink : MetronomeTheme.pinkDark.opacity(0.5))
                        .frame(width: beat == 0 ? 12 : 9, height: beat == 0 ? 12 : 9)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(context.state.bpm)")
                    .font(.system(size: 32, weight: .thin, design: .rounded))
                    .foregroundColor(.white)
                Text(context.state.tempoMarking)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(MetronomeTheme.pinkLight)
            }

            Button(intent: ToggleMetronomeIntent()) {
                Image(systemName: context.state.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(MetronomeTheme.background)
                    .frame(width: 44, height: 44)
                    .background(MetronomeTheme.pink)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(MetronomeTheme.background)
    }
}
