import SwiftUI

struct HeaderView: View {
    let viewModel: FocusViewModel

    var body: some View {
        HStack(spacing: 10) {
            OriloMark(size: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("Orilo")
                    .font(.headline.weight(.semibold))
                if let headerSubtitle {
                    Text(headerSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    private var headerSubtitle: String? {
        switch viewModel.phase {
        case .idle:
            return "Set the room for focused making"
        case .settling:
            return "Arrive before the countdown"
        case .running:
            return "Protect this intention"
        case .paused:
            return "Paused, still held"
        case .breakTime:
            return "Rest before the next round"
        case .completed:
            return nil
        }
    }
}

struct DailyStatsView: View {
    let viewModel: FocusViewModel

    var body: some View {
        HStack(spacing: 14) {
            StatBlock(title: "Today", value: "\(viewModel.todaysCompletedCount)")

            Divider()
                .frame(height: 20)

            StatBlock(title: "Focused", value: TimeFormatting.minutes(viewModel.todaysFocusedSeconds))

            if viewModel.currentStreakDays > 0 {
                Divider()
                    .frame(height: 20)

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(OriloColors.streakFlame)
                    StatBlock(title: "Streak", value: "\(viewModel.currentStreakDays)d")
                }
            }

            Spacer()

            if let latest = viewModel.todaysRecaps.first {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Last session")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(TimeFormatting.compactDate(latest.endedAt))
                        .font(.caption.weight(.medium))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(OriloColors.surfaceElevated, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(OriloColors.surfaceBorder, lineWidth: 1)
        }
    }
}

struct OriloMark: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(.primary.opacity(0.08))

            FilledFlowerMark(size: size * 0.68)
                .foregroundStyle(.primary)
        }
        .frame(width: size, height: size)
    }
}

private struct FilledFlowerMark: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                petal
                    .offset(y: -size * 0.24)
                    .rotationEffect(.degrees(Double(index) * 60))
            }

            Circle()
                .frame(width: size * 0.28, height: size * 0.28)

            Circle()
                .fill(.background)
                .frame(width: size * 0.12, height: size * 0.12)
        }
        .frame(width: size, height: size)
    }

    private var petal: some View {
        Capsule()
            .frame(width: size * 0.30, height: size * 0.50)
    }
}

private struct StatBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
        }
    }
}
