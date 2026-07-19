import Observation
import SwiftUI

struct RecapView: View {
    @Bindable var viewModel: FocusViewModel
    let recap: SessionRecap
    @FocusState private var reflectionFocused: Bool
    @State private var milestoneShown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RecapHero(viewModel: viewModel, recap: recap)

            RecapInsightBanner(suggestion: viewModel.ritualSuggestion(for: recap))

            ProtectionControl(viewModel: viewModel, recap: recap)

            VStack(alignment: .leading, spacing: 7) {
                Text("Reflection")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 9) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)

                    TextField(recap.creatorMode.reflectionPrompt, text: $viewModel.reflectionText)
                        .textFieldStyle(.plain)
                        .font(.callout)
                        .focused($reflectionFocused)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .frame(minHeight: 38)
                .background(
                    (reflectionFocused ? Color.accentColor.opacity(0.08) : Color.secondary.opacity(0.07)),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            reflectionFocused ? Color.accentColor.opacity(0.82) : Color.secondary.opacity(0.12),
                            lineWidth: reflectionFocused ? 1.5 : 1
                        )
                }
                .shadow(color: reflectionFocused ? Color.accentColor.opacity(0.18) : .clear, radius: 6, y: 1)
            }

            Button {
                viewModel.saveReflectionAndClose(for: recap)
            } label: {
                Label("Done", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .animation(.smooth(duration: 0.16), value: reflectionFocused)
        .sheet(isPresented: Binding(
            get: { viewModel.pendingMilestone != nil && !milestoneShown },
            set: { _ in milestoneShown = true }
        )) {
            if let milestone = viewModel.pendingMilestone {
                MilestoneView(milestone: milestone) {
                    milestoneShown = true
                }
            }
        }
        .onAppear {
            milestoneShown = false
        }
    }
}

private struct RecapHero: View {
    let viewModel: FocusViewModel
    let recap: SessionRecap

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.11))

                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.green)
            }
            .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Session complete")
                        .font(.headline.weight(.semibold))

                    Text(recap.intention)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    if let top = recap.topDistractionName,
                       let count = recap.distractionCounts[top], count > 0 {
                        Label("You returned to \(top) \(count)×", systemImage: "hand.raised")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .lineLimit(1)
                    }
                }

                RecapSummaryRow(viewModel: viewModel, recap: recap)
            }

            Spacer(minLength: 0)
        }
        .padding(.bottom, 2)
    }
}

private struct ProtectionControl: View {
    @Bindable var viewModel: FocusViewModel
    let recap: SessionRecap

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Was the intention protected?")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Button {
                    viewModel.setProtectedIntention(true, for: recap)
                } label: {
                    Label("Yes", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ProtectionButtonStyle(isSelected: recap.protectedIntention == true))

                Button {
                    viewModel.setProtectedIntention(false, for: recap)
                } label: {
                    Label("Revisit", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ProtectionButtonStyle(isSelected: recap.protectedIntention == false))
            }
        }
    }
}

private struct RecapInsightBanner: View {
    let suggestion: FocusViewModel.RitualSuggestion

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: suggestion.systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(suggestion.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct RecapSummaryRow: View {
    let viewModel: FocusViewModel
    let recap: SessionRecap

    var body: some View {
        HStack(spacing: 6) {
            RecapSummaryPill(text: viewModel.diagnosis(for: recap).rawValue, systemImage: viewModel.diagnosis(for: recap).systemImage)
            RecapSummaryPill(text: TimeFormatting.minutes(Int(recap.focusedDuration)), systemImage: "timer")
            RecapSummaryPill(text: TimeFormatting.minutes(Int(recap.plannedDuration)), systemImage: "target")
            if recap.totalDistractions > 0 {
                RecapSummaryPill(
                    text: "\(recap.totalDistractions) distraction\(recap.totalDistractions == 1 ? "" : "s")",
                    systemImage: "hand.raised",
                    tint: .orange
                )
            } else {
                RecapSummaryPill(text: recap.creatorMode.title, systemImage: recap.creatorMode.systemImage)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RecapSummaryPill: View {
    let text: String
    let systemImage: String
    var tint: Color? = nil

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(tint ?? .secondary)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background((tint ?? .secondary).opacity(0.06), in: Capsule())
    }
}

private struct ProtectionButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .labelStyle(.titleAndIcon)
            .imageScale(.small)
            .frame(maxWidth: .infinity, minHeight: 30)
            .padding(.horizontal, 12)
            .foregroundStyle(isSelected ? .primary : .secondary)
            .background(
                isSelected
                    ? Color.green.opacity(configuration.isPressed ? 0.16 : 0.11)
                    : Color.secondary.opacity(configuration.isPressed ? 0.11 : 0.06),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.smooth(duration: 0.12), value: configuration.isPressed)
            .animation(.smooth(duration: 0.18), value: isSelected)
    }
}
