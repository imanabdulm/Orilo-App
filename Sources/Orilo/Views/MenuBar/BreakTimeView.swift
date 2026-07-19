import Observation
import SwiftUI

struct BreakTimeView: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(viewModel.isLongBreak ? "Long Break" : "Short Break")
                        .font(.headline.weight(.semibold))

                    Text("Step away and recharge")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                BreakPomodoroCount(count: viewModel.completedPomodoroCount)
            }

            BreakTimerDial(
                timeText: TimeFormatting.clock(viewModel.breakRemainingSeconds),
                progress: viewModel.breakProgress,
                isLongBreak: viewModel.isLongBreak
            )
            .frame(maxWidth: .infinity, alignment: .center)

            BreakInfoStrip(isLongBreak: viewModel.isLongBreak)

            HStack(spacing: 10) {
                Button {
                    viewModel.skipBreak()
                } label: {
                    Label("Skip Break", systemImage: "forward.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(role: .destructive) {
                    viewModel.endSession()
                } label: {
                    Label("End Session", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }
}

// MARK: - Break Timer Dial

private struct BreakTimerDial: View {
    let timeText: String
    let progress: Double
    let isLongBreak: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.10), lineWidth: 8)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    OriloColors.breakGradient,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 5) {
                Text(timeText)
                    .font(.system(size: 46, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                HStack(spacing: 4) {
                    Image(systemName: isLongBreak ? "cup.and.saucer.fill" : "leaf.fill")
                        .font(.caption2)
                        .foregroundStyle(OriloColors.breakRing)
                    Text(isLongBreak ? "Long break" : "Short break")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 176, height: 176)
        .padding(.vertical, 2)
        .accessibilityLabel("Break timer")
        .accessibilityValue("\(timeText) remaining")
        .animation(.smooth(duration: 0.22), value: progress)
    }
}

// MARK: - Pomodoro Count

private struct BreakPomodoroCount: View {
    let count: Int

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "circle.circle.fill")
                .font(.system(size: 8))
                .foregroundStyle(OriloColors.breakRing)

            Text("\(count) done")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(OriloColors.breakRing.opacity(0.10), in: Capsule())
    }
}

// MARK: - Break Info Strip

private struct BreakInfoStrip: View {
    let isLongBreak: Bool

    private let tips = [
        "Look at something 20 feet away",
        "Stretch your shoulders",
        "Take a few deep breaths",
        "Get a glass of water",
    ]

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(OriloColors.breakRing)

            Text(tips.randomElement() ?? "Take a moment to breathe")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OriloColors.breakRing.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
    }
}
