import Observation
import SwiftUI

struct ActiveSessionView: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Label(viewModel.activeSession?.creatorMode.title ?? "Focus", systemImage: viewModel.activeSession?.creatorMode.systemImage ?? "timer")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text(viewModel.activeSession?.intention ?? "Focus")
                        .font(.headline)
                        .lineLimit(2)
                }

                Spacer(minLength: 12)

                SessionStatePill(isPaused: viewModel.phase == .paused)
            }

            FocusTimerDial(
                timeText: TimeFormatting.clock(viewModel.remainingSeconds),
                progress: viewModel.sessionProgress,
                isPaused: viewModel.phase == .paused
            )
            .frame(maxWidth: .infinity, alignment: .center)

            if let appName = viewModel.distractionAppName {
                ReminderBanner(viewModel: viewModel, appName: appName)
            } else if viewModel.areDistractionRemindersMutedForSession {
                MutedReminderBanner(viewModel: viewModel)
            }
            HStack(spacing: 8) {
                Text("Extend session:")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Button("+5m") {
                    viewModel.extendSession(byMinutes: 5)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Extend session by 5 minutes")

                Button("+15m") {
                    viewModel.extendSession(byMinutes: 15)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Extend session by 15 minutes")
            }
            .padding(.horizontal, 4)

            HStack(spacing: 10) {
                Button {
                    viewModel.isRunning ? viewModel.pauseSession() : viewModel.resumeSession()
                } label: {
                    Label(viewModel.isRunning ? "Pause" : "Resume", systemImage: viewModel.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(role: .destructive) {
                    viewModel.endSession()
                } label: {
                    Label("End", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }
}

private struct SessionStatePill: View {
    let isPaused: Bool

    var body: some View {
        HStack(spacing: 5) {
            ZStack {
                if !isPaused {
                    Circle()
                        .fill(Color.green.opacity(0.16))
                        .frame(width: 14, height: 14)
                        .opacity(0.55)
                }

                Circle()
                    .fill(isPaused ? Color.secondary : Color.green)
                    .frame(width: 6, height: 6)
            }
            .frame(width: 14, height: 14)

            Text(isPaused ? "Paused" : "Active")
                .font(.caption.weight(.medium))
                .foregroundStyle(isPaused ? .secondary : .primary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.secondary.opacity(0.09), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

private struct FocusTimerDial: View {
    let timeText: String
    let progress: Double
    let isPaused: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(isPaused ? 0.02 : 0.07))
                .opacity(isPaused ? 0 : 1)

            Circle()
                .stroke(.secondary.opacity(0.12), lineWidth: 8)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    isPaused ? Color.secondary.opacity(0.58) : Color.primary.opacity(0.78),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 5) {
                Text(timeText)
                    .font(.system(size: 46, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text(isPaused ? "Paused" : "\(Int(progress * 100))% complete")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 176, height: 176)
        .padding(.vertical, 2)
        .accessibilityLabel("Session progress")
        .accessibilityValue("\(timeText) remaining, \(Int(progress * 100)) percent complete")
        .animation(.smooth(duration: 0.22), value: progress)
        .animation(.smooth(duration: 0.18), value: isPaused)
    }
}

private struct ReminderBanner: View {
    @Bindable var viewModel: FocusViewModel
    let appName: String

    var body: some View {
        HStack(alignment: .center, spacing: 9) {
            Image(systemName: "hand.raised")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Gentle check-in")
                    .font(.subheadline.weight(.medium))
                Text("\(appName) appeared \(appearanceCount) time\(appearanceCount == 1 ? "" : "s"). Return to your intention.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button {
                viewModel.muteDistractionRemindersForCurrentSession()
            } label: {
                Image(systemName: "bell.slash.fill")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.borderless)
            .help("Mute reminders for this session")
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 7))
    }

    private var appearanceCount: Int {
        max(viewModel.currentSessionDistractionCounts[appName, default: 1], 1)
    }
}

private struct MutedReminderBanner: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 9) {
            Image(systemName: "bell.slash.fill")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Reminders muted")
                    .font(.subheadline.weight(.medium))
                Text("Distraction nudges are off for this session.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button {
                viewModel.unmuteDistractionRemindersForCurrentSession()
            } label: {
                Image(systemName: "bell.fill")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.borderless)
            .help("Unmute reminders")
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 7))
    }
}
