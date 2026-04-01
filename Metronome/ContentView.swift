import SwiftUI

struct ContentView: View {
    @StateObject private var engine = AudioEngine.shared
    @State private var bpm: Double = 120
    @State private var beatsPerMeasure: Int = 4
    @State private var subdivision: Int = 1
    @State private var isDragging = false
    @State private var isEditingBPM = false
    @State private var bpmInputText = ""

    private let subdivisionOptions: [(label: String, value: Int)] = [
        ("1", 1),
        ("2", 2),
        ("3", 3),
        ("4", 4),
    ]

    private var tempoMarking: String {
        switch Int(bpm) {
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

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                // Title
                Text("PINKDROP")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .tracking(6)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.top, 16)

                Spacer()

                // Beat indicators
                beatIndicators

                Spacer()

                // BPM display
                bpmDisplay

                // Tempo marking
                Text(tempoMarking)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.pinkLight)

                // BPM slider
                bpmSlider

                // Tap tempo + stepper
                bpmControls

                Spacer()

                // Time signature
                timeSignaturePicker

                // Subdivision picker
                subdivisionPicker

                Spacer()

                // Play/Stop button
                playButton
                    .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)

            // Custom number keypad overlay
            if isEditingBPM {
                VStack {
                    Spacer()
                    numberKeypad
                }
                .transition(.move(edge: .bottom))
                .animation(.spring(duration: 0.3), value: isEditingBPM)
            }
        }
    }

    // MARK: - Beat Indicators

    private var beatIndicators: some View {
        HStack(spacing: 12) {
            ForEach(0..<beatsPerMeasure, id: \.self) { beat in
                BeatDot(
                    isActive: engine.isPlaying && engine.currentBeat == beat,
                    isAccent: beat == 0,
                    subdivisionCount: subdivision,
                    activeSubdivision: engine.isPlaying && engine.currentBeat == beat
                        ? engine.currentSubdivision : -1
                )
            }
        }
        .animation(.easeInOut(duration: 0.1), value: engine.currentBeat)
    }

    // MARK: - BPM Display

    private var bpmDisplay: some View {
        VStack(spacing: 4) {
            Text(isEditingBPM ? (bpmInputText.isEmpty ? "___" : bpmInputText) : "\(Int(bpm))")
                .font(.system(size: 80, weight: .thin, design: .rounded))
                .foregroundColor(isEditingBPM && bpmInputText.isEmpty ? Theme.textSecondary : Theme.textPrimary)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.15), value: Int(bpm))
                .onTapGesture {
                    bpmInputText = ""
                    isEditingBPM = true
                }

            Text("BPM")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .tracking(4)
                .foregroundColor(Theme.textSecondary)
        }
    }

    // MARK: - BPM Slider

    private var bpmSlider: some View {
        VStack(spacing: 4) {
            Slider(value: $bpm, in: 20...300, step: 1) { editing in
                isDragging = editing
                if !editing {
                    engine.bpm = bpm
                    engine.updateTiming()
                }
            }
            .tint(Theme.pink)
            .onChange(of: bpm) { _, newValue in
                engine.bpm = newValue
                if engine.isPlaying {
                    engine.updateTiming()
                    LiveActivityManager.shared.updateActivity(
                        bpm: Int(newValue),
                        beatsPerMeasure: beatsPerMeasure,
                        subdivision: subdivision,
                        isPlaying: true,
                        tempoMarking: tempoMarking
                    )
                }
            }

            HStack {
                Text("20")
                Spacer()
                Text("300")
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(Theme.textSecondary)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - BPM Controls

    @State private var lastTapTime: Date?
    @State private var tapIntervals: [TimeInterval] = []

    private var bpmControls: some View {
        HStack(spacing: 16) {
            // Minus button
            Button {
                bpm = max(20, bpm - 5)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 44, height: 44)
                    .foregroundColor(Theme.pink)
                    .background(Theme.surface)
                    .clipShape(Circle())
            }

            // Tap tempo
            Button {
                handleTap()
            } label: {
                Text("TAP")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(Theme.background)
                    .frame(width: 100, height: 44)
                    .background(Theme.pinkGradient)
                    .clipShape(Capsule())
            }

            // Plus button
            Button {
                bpm = min(300, bpm + 5)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 44, height: 44)
                    .foregroundColor(Theme.pink)
                    .background(Theme.surface)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Time Signature

    private var timeSignaturePicker: some View {
        VStack(spacing: 8) {
            Text("TIME SIGNATURE")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(3)
                .foregroundColor(Theme.textSecondary)

            HStack(spacing: 8) {
                ForEach([2, 3, 4, 5, 6, 7], id: \.self) { beats in
                    Button {
                        beatsPerMeasure = beats
                        engine.beatsPerMeasure = beats
                        if engine.isPlaying {
                            LiveActivityManager.shared.updateActivity(
                                bpm: Int(bpm), beatsPerMeasure: beats,
                                subdivision: subdivision, isPlaying: true,
                                tempoMarking: tempoMarking
                            )
                        }
                    } label: {
                        Text("\(beats)/4")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .frame(width: 44, height: 36)
                            .foregroundColor(beatsPerMeasure == beats ? Theme.background : Theme.textSecondary)
                            .background(beatsPerMeasure == beats ? Theme.pink : Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    // MARK: - Subdivision Picker

    private var subdivisionPicker: some View {
        VStack(spacing: 8) {
            Text("SUBDIVISION")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(3)
                .foregroundColor(Theme.textSecondary)

            HStack(spacing: 8) {
                ForEach(subdivisionOptions, id: \.value) { option in
                    Button {
                        subdivision = option.value
                        engine.subdivision = option.value
                        engine.updateTiming()
                        if engine.isPlaying {
                            LiveActivityManager.shared.updateActivity(
                                bpm: Int(bpm), beatsPerMeasure: beatsPerMeasure,
                                subdivision: option.value, isPlaying: true,
                                tempoMarking: tempoMarking
                            )
                        }
                    } label: {
                        VStack(spacing: 2) {
                            subdivisionIcon(option.value)
                            Text(subdivisionLabel(option.value))
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                        }
                        .frame(width: 70, height: 50)
                        .foregroundColor(subdivision == option.value ? Theme.background : Theme.textSecondary)
                        .background(subdivision == option.value ? Theme.pink : Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    private func subdivisionLabel(_ value: Int) -> String {
        switch value {
        case 1: return "Quarter"
        case 2: return "Eighth"
        case 3: return "Triplet"
        case 4: return "16th"
        default: return ""
        }
    }

    @ViewBuilder
    private func subdivisionIcon(_ value: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<value, id: \.self) { i in
                Circle()
                    .frame(width: i == 0 ? 7 : 5, height: i == 0 ? 7 : 5)
            }
        }
    }

    // MARK: - Play Button

    private var playButton: some View {
        Button {
            if engine.isPlaying {
                engine.stop()
                Task { await LiveActivityManager.shared.endActivity() }
            } else {
                engine.bpm = bpm
                engine.beatsPerMeasure = beatsPerMeasure
                engine.subdivision = subdivision
                engine.start()
                LiveActivityManager.shared.startActivity(
                    bpm: Int(bpm),
                    beatsPerMeasure: beatsPerMeasure,
                    subdivision: subdivision,
                    tempoMarking: tempoMarking
                )
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Theme.pink)
                    .frame(width: 72, height: 72)
                    .shadow(color: Theme.pinkGlow, radius: engine.isPlaying ? 20 : 8)

                Image(systemName: engine.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Theme.background)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: engine.isPlaying)
    }

    // MARK: - Number Keypad

    private var numberKeypad: some View {
        VStack(spacing: 1) {
            // Divider line
            Theme.pink.frame(height: 1).opacity(0.3)

            VStack(spacing: 12) {
                ForEach(0..<3) { row in
                    HStack(spacing: 12) {
                        ForEach(1...3, id: \.self) { col in
                            let digit = row * 3 + col
                            keypadButton(label: "\(digit)") {
                                handleKeypadInput("\(digit)")
                            }
                        }
                    }
                }
                HStack(spacing: 12) {
                    // Delete
                    keypadButton(label: "delete.left", isSymbol: true) {
                        if !bpmInputText.isEmpty {
                            bpmInputText.removeLast()
                        }
                    }
                    // 0
                    keypadButton(label: "0") {
                        handleKeypadInput("0")
                    }
                    // Done
                    keypadButton(label: "checkmark", isSymbol: true, isAccent: true) {
                        commitBPMInput()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 32)
            .background(Theme.surface)
        }
    }

    @ViewBuilder
    private func keypadButton(label: String, isSymbol: Bool = false, isAccent: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if isSymbol {
                    Image(systemName: label)
                        .font(.system(size: 22, weight: .medium))
                } else {
                    Text(label)
                        .font(.system(size: 28, weight: .regular, design: .rounded))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundColor(isAccent ? Theme.background : Theme.textPrimary)
            .background(isAccent ? Theme.pink : Theme.surfaceLight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func handleKeypadInput(_ digit: String) {
        let candidate = bpmInputText + digit
        if candidate.count <= 3, let value = Int(candidate), value <= 300 {
            bpmInputText = candidate
        }
    }

    // MARK: - Tap Tempo Logic

    private func commitBPMInput() {
        if let value = Double(bpmInputText), value >= 20 {
            bpm = min(300, max(20, round(value)))
            engine.bpm = bpm
            engine.updateTiming()
        }
        isEditingBPM = false
    }

    private func handleTap() {
        let now = Date()
        if let last = lastTapTime {
            let interval = now.timeIntervalSince(last)
            if interval < 2.0 {
                tapIntervals.append(interval)
                if tapIntervals.count > 4 {
                    tapIntervals.removeFirst()
                }
                let avgInterval = tapIntervals.reduce(0, +) / Double(tapIntervals.count)
                bpm = min(300, max(20, round(60.0 / avgInterval)))
                engine.bpm = bpm
                engine.updateTiming()
            } else {
                tapIntervals = []
            }
        }
        lastTapTime = now
    }
}

// MARK: - Beat Dot View

struct BeatDot: View {
    let isActive: Bool
    let isAccent: Bool
    let subdivisionCount: Int
    let activeSubdivision: Int

    var body: some View {
        VStack(spacing: 6) {
            // Main beat dot
            Circle()
                .fill(isActive ? Theme.pink : Theme.surfaceLight)
                .frame(width: isAccent ? 24 : 18, height: isAccent ? 24 : 18)
                .shadow(color: isActive ? Theme.pinkGlow : .clear, radius: 8)
                .scaleEffect(isActive ? 1.2 : 1.0)

            // Subdivision dots
            if subdivisionCount > 1 {
                HStack(spacing: 3) {
                    ForEach(1..<subdivisionCount, id: \.self) { sub in
                        Circle()
                            .fill(isActive && activeSubdivision == sub
                                  ? Theme.pinkLight
                                  : Theme.surface)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .animation(.easeOut(duration: 0.08), value: isActive)
        .animation(.easeOut(duration: 0.08), value: activeSubdivision)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
