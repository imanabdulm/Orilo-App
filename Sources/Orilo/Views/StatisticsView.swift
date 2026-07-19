import Charts
import Observation
import SwiftUI

struct StatisticsView: View {
    @Bindable var viewModel: FocusViewModel

    @State private var showingExportError = false

    var body: some View {
        VStack(alignment: .leading, spacing: OriloSpacing.lg) {
            header

            summaryCards

            weeklyChart

            HStack(alignment: .top, spacing: OriloSpacing.lg) {
                topIntentions
                weeklyComparison
            }
        }
        .alert("Could not export sessions", isPresented: $showingExportError) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text("Orilo could not create the file. Try again, or choose another save location.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: OriloSpacing.xs) {
                Text("Focus proof")
                    .font(.title2.weight(.semibold))
                Text("Track the outcomes, modes, and rhythms that keep moving forward.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: OriloSpacing.sm) {
                if viewModel.currentStreakDays > 0 {
                    Button {
                        shareStreak()
                    } label: {
                        Label("Share Streak", systemImage: "square.and.arrow.up")
                    }
                    .help("Share your streak card")
                }

                Button {
                    exportCSV()
                } label: {
                    Label("CSV", systemImage: "tablecells")
                }
                .help("Export history as CSV")

                Button {
                    exportJSON()
                } label: {
                    Label("JSON", systemImage: "curlybraces")
                }
                .help("Export history as JSON")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: OriloSpacing.md) {
            StatsSummaryCard(
                title: "Total Sessions",
                value: "\(viewModel.recaps.count)",
                systemImage: "checkmark.circle",
                color: Color.accentColor
            )
            StatsSummaryCard(
                title: "Total Focused",
                value: totalFocusedFormatted,
                systemImage: "timer",
                color: Color.accentColor
            )
            StatsSummaryCard(
                title: "Avg Session",
                value: avgSessionFormatted,
                systemImage: "chart.bar",
                color: Color.teal
            )
            StatsSummaryCard(
                title: "Current Streak",
                value: "\(viewModel.currentStreakDays)d",
                systemImage: "flame.fill",
                color: OriloColors.streakFlame
            )
            StatsSummaryCard(
                title: "Best Streak",
                value: "\(viewModel.longestStreak)d",
                systemImage: "trophy.fill",
                color: Color.orange
            )
        }
    }

    private var weeklyChart: some View {
        StatsSurface {
            VStack(alignment: .leading, spacing: OriloSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last 7 Days")
                            .font(.headline.weight(.semibold))
                        Text("Daily focus time in minutes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    let totalMin = weeklyChartData.reduce(0) { $0 + $1.minutes }
                    Text("\(totalMin)m total")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Chart {
                    ForEach(weeklyChartData, id: \.day) { entry in
                        BarMark(
                            x: .value("Day", entry.label),
                            y: .value("Minutes", entry.minutes)
                        )
                        .foregroundStyle(Color.accentColor)
                        .cornerRadius(4)
                    }
                }
                .chartYAxisLabel("minutes")
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .frame(height: 180)
            }
        }
    }

    // MARK: - Top Intentions

    private var topIntentions: some View {
        StatsSurface {
            VStack(alignment: .leading, spacing: OriloSpacing.md) {
                Text("Top Intentions")
                    .font(.headline.weight(.semibold))

                if topIntentionsList.isEmpty {
                    VStack(spacing: 6) {
                        Text("No repeated intentions yet")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text("Orilo will surface the outcomes you protect most often.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .center)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(topIntentionsList.enumerated()), id: \.offset) { index, item in
                            HStack(spacing: OriloSpacing.sm) {
                                Text("\(index + 1)")
                                    .font(.caption.weight(.bold).monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)

                                Text(item.intention)
                                    .font(.callout)
                                    .lineLimit(1)

                                Spacer()

                                Text("\(item.count) sessions")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, OriloSpacing.sm)

                            if index < topIntentionsList.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Weekly Comparison

    private var weeklyComparison: some View {
        StatsSurface {
            VStack(alignment: .leading, spacing: OriloSpacing.md) {
                Text("Weekly Comparison")
                    .font(.headline.weight(.semibold))

                VStack(spacing: OriloSpacing.md) {
                    WeekComparisonRow(
                        title: "This Week",
                        minutes: thisWeekMinutes,
                        isCurrent: true
                    )

                    WeekComparisonRow(
                        title: "Last Week",
                        minutes: lastWeekMinutes,
                        isCurrent: false
                    )

                    Divider()

                    HStack {
                        Text("Difference")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        let diff = thisWeekMinutes - lastWeekMinutes
                        HStack(spacing: 4) {
                            Image(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption.weight(.bold))
                            Text("\(abs(diff))m")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                        }
                        .foregroundStyle(diff >= 0 ? OriloColors.successGreen : .secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Data

    private var totalFocusedFormatted: String {
        let totalSeconds = Int(viewModel.recaps.reduce(0) { $0 + $1.focusedDuration })
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private var avgSessionFormatted: String {
        guard !viewModel.recaps.isEmpty else { return "0m" }
        let total = viewModel.recaps.reduce(0) { $0 + $1.focusedDuration }
        let avgMinutes = Int(total / Double(viewModel.recaps.count)) / 60
        return "\(avgMinutes)m"
    }

    private struct WeeklyEntry {
        let day: Date
        let label: String
        let minutes: Int
    }

    private var weeklyChartData: [WeeklyEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return (0..<7).reversed().map { daysAgo in
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayRecaps = viewModel.recaps.filter { calendar.isDate($0.endedAt, inSameDayAs: day) }
            let minutes = Int(dayRecaps.reduce(0) { $0 + $1.focusedDuration }) / 60
            return WeeklyEntry(day: day, label: formatter.string(from: day), minutes: minutes)
        }
    }

    private struct IntentionEntry {
        let intention: String
        let count: Int
    }

    private var topIntentionsList: [IntentionEntry] {
        let grouped = Dictionary(grouping: viewModel.recaps) {
            $0.intention.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        return grouped
            .filter { !$0.key.isEmpty }
            .map { key, recaps in
                IntentionEntry(intention: recaps.first?.intention ?? key, count: recaps.count)
            }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }
    }

    private var thisWeekMinutes: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        guard let startOfWeek = calendar.date(byAdding: .day, value: -6, to: startOfToday) else { return 0 }
        let recaps = viewModel.recaps.filter { $0.endedAt >= startOfWeek }
        return Int(recaps.reduce(0) { $0 + $1.focusedDuration }) / 60
    }

    private var lastWeekMinutes: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        guard let endOfLastWeek = calendar.date(byAdding: .day, value: -7, to: startOfToday),
              let startOfLastWeek = calendar.date(byAdding: .day, value: -13, to: startOfToday) else { return 0 }
        let recaps = viewModel.recaps.filter { $0.endedAt >= startOfLastWeek && $0.endedAt < endOfLastWeek }
        return Int(recaps.reduce(0) { $0 + $1.focusedDuration }) / 60
    }

    // MARK: - Export

    private func shareStreak() {
        let totalMinutes = Int(viewModel.recaps.reduce(0) { $0 + $1.focusedDuration }) / 60
        let data = ShareStreakService.StreakCardData(
            streakDays: viewModel.currentStreakDays,
            totalSessions: viewModel.recaps.count,
            focusedMinutes: totalMinutes,
            topIntention: topIntentionsList.first?.intention ?? "" // Was viewModel.topIntention but we can just use topIntentionsList.first
        )
        ShareStreakService.generateAndShare(data: data)
    }

    private func exportCSV() {
        guard let sourceURL = viewModel.exportToCSV() else {
            showingExportError = true
            return
        }
        presentSavePanel(sourceURL: sourceURL, suggestedName: "orilo_sessions.csv", fileType: "csv")
    }

    private func exportJSON() {
        guard let sourceURL = viewModel.exportToJSON() else {
            showingExportError = true
            return
        }
        presentSavePanel(sourceURL: sourceURL, suggestedName: "orilo_sessions.json", fileType: "json")
    }

    private func presentSavePanel(sourceURL: URL, suggestedName: String, fileType: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedName
        panel.allowedContentTypes = fileType == "csv"
            ? [.commaSeparatedText]
            : [.json]
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let destination = panel.url {
            try? FileManager.default.copyItem(at: sourceURL, to: destination)
        }
    }
}

// MARK: - Supporting Views

private struct StatsSummaryCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: OriloSpacing.sm) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(OriloSpacing.cardPadding)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .background(OriloColors.surfaceElevated, in: RoundedRectangle(cornerRadius: OriloRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: OriloRadius.md, style: .continuous)
                .stroke(OriloColors.surfaceBorder, lineWidth: 1)
        }
    }
}

private struct WeekComparisonRow: View {
    let title: String
    let minutes: Int
    let isCurrent: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(isCurrent ? OriloColors.focusRing : Color.secondary.opacity(0.3))
                .frame(width: 8, height: 8)

            Text(title)
                .font(.subheadline.weight(.medium))

            Spacer()

            Text("\(minutes)m")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(isCurrent ? .primary : .secondary)
        }
    }
}

private struct StatsSurface<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(OriloSpacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(OriloColors.surfaceElevated, in: RoundedRectangle(cornerRadius: OriloRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: OriloRadius.md, style: .continuous)
                    .stroke(OriloColors.surfaceBorder, lineWidth: 1)
            }
    }
}


