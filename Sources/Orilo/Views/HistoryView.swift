import Observation
import SwiftUI

enum AnalyticsTab: String, CaseIterable, Identifiable {
    case statistics = "Overview & Proof"
    case history = "Daily Log & History"

    var id: String { rawValue }
}

struct HistoryView: View {
    @Bindable var viewModel: FocusViewModel
    @State private var selectedTab: AnalyticsTab = .statistics
    @State private var selectedRecapDate = Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OriloSpacing.lg) {
                topTabBar

                if selectedTab == .statistics {
                    StatisticsView(viewModel: viewModel)
                } else {
                    historyContent
                }
            }
            .padding(OriloSpacing.xl)
        }
        .frame(minWidth: 740, minHeight: 520)
    }

    private var topTabBar: some View {
        Picker("View Mode", selection: $selectedTab) {
            ForEach(AnalyticsTab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 350)
    }

    private var historyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            InsightsSummaryView(viewModel: viewModel)
            DailyRecapView(viewModel: viewModel, selectedDate: $selectedRecapDate)

            if viewModel.recaps.isEmpty {
                EmptyHistoryView()
            } else {
                SessionsListView(viewModel: viewModel)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Insights")
                    .font(.title2.weight(.semibold))
                Text("Patterns from your intentions, attention, and follow-through.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("History range", selection: $viewModel.historyFilter) {
                ForEach(FocusViewModel.HistoryFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 210)
        }
    }
}

private struct DailyRecapView: View {
    let viewModel: FocusViewModel
    @Binding var selectedDate: Date

    private var dayRecaps: [SessionRecap] {
        viewModel.recaps
            .filter { Calendar.current.isDate($0.endedAt, inSameDayAs: selectedDate) }
            .sorted { $0.endedAt > $1.endedAt }
    }

    var body: some View {
        HistorySurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Daily recap")
                            .font(.headline.weight(.semibold))
                        Text(dayTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    RecapDateControl(selectedDate: $selectedDate)
                }

                if dayRecaps.isEmpty {
                    Text(Calendar.current.isDateInToday(selectedDate)
                         ? "No rituals closed today. Start one protected outcome from the menu bar."
                         : "No rituals were closed on this date.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                } else {
                    HStack(alignment: .center, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(dailySignal)
                                .font(.callout.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)

                            Text(dailyDetail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Divider()
                            .frame(height: 40)

                        HStack(spacing: 18) {
                            CompactInsightMetric(title: "Focused", value: focusedText)
                            CompactInsightMetric(title: "Clean", value: "\(cleanCount)")
                            CompactInsightMetric(title: "Protected", value: protectedText)
                        }
                        .frame(width: 260, alignment: .trailing)
                    }
                }
            }
        }
    }

    private var dayTitle: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        }

        if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        }

        return selectedDate.formatted(date: .abbreviated, time: .omitted)
    }

    private var focusedText: String {
        TimeFormatting.minutes(Int(dayRecaps.reduce(0) { $0 + $1.focusedDuration }))
    }

    private var cleanCount: Int {
        dayRecaps.filter { $0.totalDistractions == 0 }.count
    }

    private var protectedText: String {
        let answered = dayRecaps.compactMap(\.protectedIntention)
        guard !answered.isEmpty else {
            return "-"
        }

        let protectedCount = answered.filter { $0 }.count
        return "\(Int((Double(protectedCount) / Double(answered.count) * 100).rounded()))%"
    }

    private var dailySignal: String {
        if let revisit = dayRecaps.first(where: { $0.protectedIntention == false }) {
            return "Continue: \(revisit.intention)"
        }

        if let interrupted = dayRecaps.first(where: { $0.totalDistractions > 0 }) {
            return "Guard against \(interrupted.topDistractionName ?? "interruptions")"
        }

        return "Clean focus day"
    }

    private var dailyDetail: String {
        if let topDistraction {
            return "\(topDistraction.name) appeared \(topDistraction.count) time\(topDistraction.count == 1 ? "" : "s") on this date."
        }

        return "\(dayRecaps.count) session\(dayRecaps.count == 1 ? "" : "s") completed with no tracked interruptions."
    }

    private var topDistraction: (name: String, count: Int)? {
        dayRecaps
            .flatMap { $0.distractionCounts }
            .reduce(into: [String: Int]()) { totals, item in
                totals[item.key, default: 0] += item.value
            }
            .max { lhs, rhs in lhs.value < rhs.value }
            .map { (name: $0.key, count: $0.value) }
    }
}

private struct RecapDateControl: View {
    @Binding var selectedDate: Date
    @State private var showsDatePicker = false

    var body: some View {
        HStack(spacing: 6) {
            Button {
                moveDay(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help("Previous day")

            Button {
                showsDatePicker.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11, weight: .semibold))
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .frame(minWidth: 72)
                }
                .padding(.horizontal, 8)
                .frame(height: 24)
                .background(.secondary.opacity(0.07), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showsDatePicker, arrowEdge: .top) {
                DatePicker("Recap date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding(12)
                    .frame(width: 260)
            }
            .help("Choose date")

            Button {
                moveDay(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .disabled(Calendar.current.isDateInToday(selectedDate))
            .opacity(Calendar.current.isDateInToday(selectedDate) ? 0.35 : 1)
            .help("Next day")
        }
        .padding(3)
        .background(.primary.opacity(0.04), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        }
    }

    private var label: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        }

        if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        }

        return selectedDate.formatted(.dateTime.month(.abbreviated).day())
    }

    private func moveDay(_ value: Int) {
        guard let newDate = Calendar.current.date(byAdding: .day, value: value, to: selectedDate) else {
            return
        }

        if value > 0, newDate > Date() {
            selectedDate = Date()
        } else {
            selectedDate = newDate
        }
    }
}

private struct InsightsSummaryView: View {
    let viewModel: FocusViewModel

    var body: some View {
        HistorySurface {
            HStack(alignment: .center, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Next ritual", systemImage: viewModel.nextRitualSuggestion.systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(viewModel.nextRitualSuggestion.title)
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text(viewModel.nextRitualSuggestion.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 46)

                HStack(spacing: 20) {
                    ForEach(viewModel.weeklyProofMetrics) { metric in
                        CompactInsightMetric(title: metric.title, value: metric.value)
                            .help(metric.detail)
                    }
                }
                .frame(width: 270, alignment: .trailing)
            }
        }
    }
}

private struct CompactInsightMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.weight(.semibold).monospacedDigit())
                .lineLimit(1)
        }
        .frame(width: 70, alignment: .trailing)
    }
}

private struct SessionsListView: View {
    let viewModel: FocusViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Sessions")
                    .font(.headline.weight(.semibold))
                Spacer()
                Text("\(viewModel.filteredHistoryRecaps.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.09), in: Capsule())
            }

            SessionTableHeader()
                .padding(.horizontal, 16)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                    ForEach(viewModel.historySections) { section in
                        HistorySectionHeader(section: section)
                            .padding(.horizontal, 16)
                            .padding(.top, 14)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            ForEach(Array(section.recaps.enumerated()), id: \.element.id) { index, recap in
                                HistoryRecapRow(recap: recap, diagnosis: viewModel.diagnosis(for: recap))

                                if index < section.recaps.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .historySurfaceStroke(cornerRadius: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct SessionTableHeader: View {
    var body: some View {
        HStack(spacing: 16) {
            Text("Intention")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Result")
                .frame(width: 96, alignment: .leading)
            Text("Focus")
                .frame(width: 64, alignment: .trailing)
            Text("Ended")
                .frame(width: 92, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.top, 2)
        .padding(.bottom, 4)
    }
}

private struct HistorySectionHeader: View {
    let section: FocusViewModel.HistorySection

    var body: some View {
        HStack {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            Text("\(section.recaps.count) • \(focusedTime)")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .textCase(nil)
    }

    private var title: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(section.day) {
            return "Today"
        }

        if calendar.isDateInYesterday(section.day) {
            return "Yesterday"
        }

        return section.day.formatted(date: .abbreviated, time: .omitted)
    }

    private var focusedTime: String {
        TimeFormatting.minutes(Int(section.recaps.reduce(0) { $0 + $1.focusedDuration }))
    }
}

private struct HistoryRecapRow: View {
    let recap: SessionRecap
    let diagnosis: FocusViewModel.RecapDiagnosis
    @State private var showsReflection = false

    private var reflection: String? {
        guard let text = recap.reflection?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return nil }
        return text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text(recap.intention)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)

                    if reflection != nil {
                        Button {
                            showsReflection.toggle()
                        } label: {
                            Image(systemName: "quote.bubble")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("View reflection")
                        .popover(isPresented: $showsReflection, arrowEdge: .bottom) {
                            ReflectionPopover(intention: recap.intention, text: reflection ?? "")
                        }
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: recap.creatorMode.systemImage)
                        .font(.caption)
                        .frame(width: 14, alignment: .center)
                    Text(recap.creatorMode.title)
                        .font(.subheadline)
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SessionResultBadge(diagnosis: diagnosis, distractions: recap.totalDistractions)
                .frame(width: 96, alignment: .leading)

            Text(TimeFormatting.minutes(Int(recap.focusedDuration)))
                .font(.callout.weight(.medium).monospacedDigit())
                .lineLimit(1)
                .frame(width: 64, alignment: .trailing)

            Text(recap.endedAt.formatted(date: .omitted, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 92, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 62)
    }
}

private struct ReflectionPopover: View {
    let intention: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Reflection", systemImage: "quote.opening")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(intention)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(width: 280, alignment: .leading)
    }
}

private struct SessionResultBadge: View {
    let diagnosis: FocusViewModel.RecapDiagnosis
    let distractions: Int

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: diagnosis.systemImage)
                .font(.system(size: 11, weight: .semibold))

            Text(title)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
        }
        .foregroundStyle(color)
    }

    private var title: String {
        switch diagnosis {
        case .clean:
            return "Clean"
        case .interrupted:
            return "\(distractions)x"
        case .revisit:
            return "Revisit"
        }
    }

    private var color: Color {
        switch diagnosis {
        case .clean:
            return .secondary
        case .interrupted, .revisit:
            return .orange
        }
    }
}

private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(.secondary.opacity(0.08))
                Image(systemName: "timer.circle.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 58, height: 58)

            Text("No proof yet")
                .font(.headline.weight(.semibold))

            Text("Close your first focus ritual to see what stayed clean, what pulled attention, and what deserves another pass.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 34)
        .background(.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        .historySurfaceStroke(cornerRadius: 10)
    }
}

private struct HistorySurface<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(OriloSpacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(OriloColors.surfaceElevated, in: RoundedRectangle(cornerRadius: OriloRadius.md, style: .continuous))
            .historySurfaceStroke(cornerRadius: OriloRadius.md)
    }
}

private extension View {
    func historySurfaceStroke(cornerRadius: CGFloat) -> some View {
        overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        }
    }
}
