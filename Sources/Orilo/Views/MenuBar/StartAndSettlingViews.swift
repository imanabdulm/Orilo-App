import Observation
import SwiftUI

struct SettlingView: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Settle into the work")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text(viewModel.activeSession?.intention ?? "Focus")
                        .font(.title3.weight(.semibold))
                        .lineLimit(2)
                }

                Spacer(minLength: 12)

                Text("Ritual")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.secondary.opacity(0.09), in: Capsule())
            }

            SettlingCountdownDial(seconds: viewModel.settleRemainingSeconds)
                .frame(maxWidth: .infinity, alignment: .center)

            RitualStepStrip(seconds: viewModel.settleRemainingSeconds)

            HStack(spacing: 10) {
                Button {
                    viewModel.skipSettling()
                } label: {
                    Label("Start Now", systemImage: "forward.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(role: .destructive) {
                    viewModel.endSession()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }
}

struct StartSessionView: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CreatorModePicker(viewModel: viewModel)

            IntentionInputView(viewModel: viewModel)

            DurationPickerView(viewModel: viewModel)

            Button {
                viewModel.startSession()
            } label: {
                Label("Begin", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.canStart)
            .tint(viewModel.canStart ? .accentColor : .secondary)
            .opacity(viewModel.canStart ? 1 : 0.62)
        }
    }
}

private struct IntentionInputView: View {
    @Bindable var viewModel: FocusViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.selectedCreatorMode.ritualPrompt)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            HStack {
                TextField("What matters right now?", text: $viewModel.intention)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .focused($isFocused)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(minHeight: 38)
            .background(
                (isFocused ? Color.accentColor.opacity(0.08) : Color.secondary.opacity(0.07)),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isFocused ? Color.accentColor.opacity(0.82) : Color.secondary.opacity(0.12),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            }
            .shadow(color: isFocused ? Color.accentColor.opacity(0.18) : .clear, radius: 6, y: 1)
            .animation(.smooth(duration: 0.16), value: isFocused)
        }
    }
}

private struct CreatorModePicker: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        HStack(spacing: 10) {
            Text("Creator mode")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            Menu {
                ForEach(CreatorMode.allCases) { mode in
                    Button {
                        viewModel.selectCreatorMode(mode)
                    } label: {
                        Label(mode.title, systemImage: mode.systemImage)
                    }
                }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: viewModel.selectedCreatorMode.systemImage)
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 15)
                    Text(viewModel.selectedCreatorMode.title)
                        .font(.caption.weight(.semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(.secondary.opacity(0.07), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.secondary.opacity(0.11), lineWidth: 1)
                }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }
}

private struct SettlingCountdownDial: View {
    let seconds: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    private var progress: Double {
        1 - (Double(max(seconds, 0)) / 5)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.08))
                .scaleEffect(breathing && !reduceMotion ? 1.12 : 0.94)
                .opacity(breathing && !reduceMotion ? 0.35 : 0.7)

            Circle()
                .stroke(.secondary.opacity(0.11), lineWidth: 7)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.accentColor.opacity(0.78),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 3) {
                Text("\(seconds)")
                    .font(.system(size: 48, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("seconds")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(cueText)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: 148, height: 148)
        .padding(.vertical, 3)
        .accessibilityLabel("Settle countdown")
        .accessibilityValue("\(seconds) seconds")
        .animation(.smooth(duration: 0.22), value: seconds)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
    }

    private var cueText: String {
        switch seconds {
        case 4...5:
            return "clear space"
        case 2...3:
            return "breathe"
        default:
            return "begin"
        }
    }
}

private struct RitualStepStrip: View {
    let seconds: Int

    private let steps: [(String, String)] = [
        ("rectangle.dashed", "Clear"),
        ("wind", "Breathe"),
        ("play.fill", "Begin")
    ]

    var body: some View {
        HStack(spacing: 7) {
            ForEach(Array(steps.enumerated()), id: \.element.1) { index, step in
                let isActive = index == activeIndex

                Label(step.1, systemImage: step.0)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isActive ? Color.primary : Color.secondary)
                    .labelStyle(.titleAndIcon)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(isActive ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 7))
                    .scaleEffect(isActive ? 1.015 : 1)
                    .animation(.smooth(duration: 0.18), value: activeIndex)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Clear, breathe, begin")
    }

    private var activeIndex: Int {
        switch seconds {
        case 4...5:
            return 0
        case 2...3:
            return 1
        default:
            return 2
        }
    }
}

private struct DurationPickerView: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(viewModel.durationPresets, id: \.self) { minutes in
                    Button("\(minutes)m") {
                        viewModel.selectDuration(minutes)
                    }
                    .buttonStyle(DurationButtonStyle(isSelected: !viewModel.isCustomDurationSelected && viewModel.selectedDurationMinutes == minutes))
                }

                Button("Custom") {
                    viewModel.selectCustomDuration()
                }
                .buttonStyle(DurationButtonStyle(isSelected: viewModel.isCustomDurationSelected))
            }

            if viewModel.isCustomDurationSelected {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Custom time")
                            .font(.caption.weight(.medium))
                        Text("5 minute steps")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)

                    CustomDurationControl(viewModel: viewModel)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.11), lineWidth: 1)
                }
            }

            if viewModel.preferences.pomodoroEnabled {
                HStack(spacing: 6) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Auto break: \(viewModel.preferences.breakDurationMinutes)m")
                    Text("Long \(viewModel.preferences.longBreakDurationMinutes)m after \(viewModel.preferences.sessionsBeforeLongBreak)")
                        .foregroundStyle(.tertiary)
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.secondary.opacity(0.055), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
                }
            }
        }
    }
}

struct CustomDurationControl: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        CapsuleStepper(
            value: Binding(
                get: { viewModel.customDurationMinutes },
                set: { viewModel.updateCustomDuration($0) }
            ),
            range: 5...180,
            step: 5,
            suffix: "m",
            label: "custom duration"
        )
    }
}

/// A compact capsule-pill stepper (− value +) with monospaced digits and a
/// smooth numeric transition. Shared by the custom-duration control and the
/// Pomodoro break controls so they all look identical.
struct CapsuleStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    var suffix: String = ""
    var label: String = "value"

    var body: some View {
        HStack(spacing: 6) {
            Button {
                value = max(value - step, range.lowerBound)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .disabled(value <= range.lowerBound)
            .help("Decrease \(label)")

            Text("\(value)\(suffix)")
                .font(.callout.weight(.semibold).monospacedDigit())
                .frame(width: 48)
                .contentTransition(.numericText())

            Button {
                value = min(value + step, range.upperBound)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .disabled(value >= range.upperBound)
            .help("Increase \(label)")
        }
        .padding(3)
        .background(.primary.opacity(0.06), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        }
        .animation(.smooth(duration: 0.16), value: value)
    }
}

private struct DurationButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(isSelected ? .semibold : .regular))
            .frame(minWidth: 58)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color.primary.opacity(configuration.isPressed ? 0.16 : 0.11) : Color.secondary.opacity(configuration.isPressed ? 0.12 : 0.06),
                in: RoundedRectangle(cornerRadius: 7)
            )
    }
}
