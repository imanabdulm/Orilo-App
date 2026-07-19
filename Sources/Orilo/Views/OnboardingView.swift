import Observation
import SwiftUI

struct OnboardingView: View {
    @Bindable var viewModel: FocusViewModel
    @Environment(\.dismiss) private var dismiss

    let onComplete: () -> Void

    @State private var currentPage = 0

    init(viewModel: FocusViewModel, onComplete: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ValuePage()
                    .tag(0)

                SetupPage(viewModel: viewModel)
                    .tag(1)

                ReadyPage {
                    viewModel.completeOnboarding()
                    onComplete()
                    dismiss()
                }
                .tag(2)
            }
            .tabViewStyle(.automatic)
            .animation(OriloAnimation.smooth, value: currentPage)

            OnboardingNavigation(
                currentPage: $currentPage,
                pageCount: 3,
                nextTitle: nextButtonTitle
            )
        }
        .frame(width: 500, height: 500)
    }

    private var nextButtonTitle: String {
        switch currentPage {
        case 0:
            return "Set up"
        case 1:
            return "Finish"
        default:
            return "Next"
        }
    }
}

private struct OnboardingNavigation: View {
    @Binding var currentPage: Int
    let pageCount: Int
    let nextTitle: String

    var body: some View {
        ZStack {
            // Center dots absolutely so the Back button appearing/disappearing
            // on the sides never shifts them.
            HStack(spacing: 7) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.28))
                        .frame(width: index == currentPage ? 18 : 7, height: 7)
                        .animation(.smooth(duration: 0.18), value: currentPage)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Button("Back") {
                    withAnimation(OriloAnimation.smooth) {
                        currentPage -= 1
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .opacity(currentPage > 0 ? 1 : 0)
                .disabled(currentPage == 0)

                Spacer()

                Button(nextTitle) {
                    withAnimation(OriloAnimation.smooth) {
                        currentPage += 1
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .opacity(currentPage < pageCount - 1 ? 1 : 0)
                .disabled(currentPage >= pageCount - 1)
            }
        }
        .padding(.horizontal, OriloSpacing.xl)
        .padding(.bottom, OriloSpacing.lg)
    }
}

private struct ValuePage: View {
    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    OriloMiniMark()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Protect one outcome")
                            .font(.system(size: 30, weight: .semibold))
                            .lineLimit(1)

                        Text("A menu bar ritual for creators who want focus to end with proof, not just time spent.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(spacing: 8) {
                    OnboardingValueRow(
                        index: 0,
                        icon: "target",
                        title: "Name the outcome",
                        detail: "Choose the line, draft, task, or decision this session should move forward.",
                        tint: OriloColors.gradientStart
                    )

                    OnboardingValueRow(
                        index: 1,
                        icon: "shield.lefthalf.filled",
                        title: "Shield your focus",
                        detail: "Open a distraction — even a site like YouTube in your browser — and Orilo gently blocks the screen until you choose to return.",
                        tint: OriloColors.gradientMid
                    )

                    OnboardingValueRow(
                        index: 2,
                        icon: "checkmark.seal",
                        title: "Close with proof",
                        detail: "See what stayed clean, what interrupted you, and what deserves another pass.",
                        tint: OriloColors.successGreen
                    )
                }
            }
        }
    }
}

private struct SetupPage: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Make it yours")
                        .font(.title2.weight(.semibold))
                    Text("Set useful defaults for the first ritual. You can change these later.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 10) {
                    SetupDurationCard(viewModel: viewModel)
                    PermissionSetupCard(viewModel: viewModel)
                    DistractionSetupCard(viewModel: viewModel)
                }
            }
        }
    }
}

private struct ReadyPage: View {
    let onBegin: () -> Void
    @State private var isPulsing = false

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    OriloMiniMark()

                    Text("Start from the menu bar")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, OriloColors.gradientMid],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Orilo is ready. Begin by protecting one outcome for one session.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("First ritual")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    HStack(spacing: 12) {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(OriloColors.gradientStart)
                            .frame(width: 24)

                        Text("What matters right now?")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 60)
                    .background(
                        Color.secondary.opacity(0.05),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(OriloColors.gradientMid.opacity(0.3), lineWidth: 1.5)
                    }
                }

                Spacer()

                Button {
                    onBegin()
                } label: {
                    Label("Begin from menu bar", systemImage: "play.fill")
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .shadow(color: OriloColors.gradientMid.opacity(isPulsing ? 0.6 : 0.3), radius: isPulsing ? 15 : 8, y: isPulsing ? 6 : 4)
                .scaleEffect(isPulsing ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
                .onAppear {
                    isPulsing = true
                }
            }
        }
    }
}

private struct OnboardingPage<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            // Subtle animated gradient background
            LinearGradient(
                colors: [
                    Color(NSColor.windowBackgroundColor),
                    Color(NSColor.windowBackgroundColor),
                    OriloColors.gradientStart.opacity(0.04),
                    OriloColors.gradientMid.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            content
                .padding(.horizontal, 36)
                .padding(.top, 36)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct OriloMiniMark: View {
    @State private var isBreathing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(OriloColors.primaryGradient)
                .scaleEffect(isBreathing ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: isBreathing)

            Image(systemName: "camera.macro.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)
        }
        .frame(width: 44, height: 44)
        .shadow(color: OriloColors.gradientMid.opacity(0.4), radius: isBreathing ? 12 : 6, y: isBreathing ? 4 : 2)
        .onAppear {
            isBreathing = true
        }
    }
}

private struct OnboardingValueRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var isHovered = false

    let index: Int
    let icon: String
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(tint)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 38, height: 38)
            .shadow(color: tint.opacity(isHovered ? 0.6 : 0.35), radius: isHovered ? 8 : 5, y: isHovered ? 4 : 2)
            .scaleEffect(isHovered ? 1.05 : 1.0)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isHovered ? Color.primary : Color.primary.opacity(0.9))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            Color.secondary.opacity(isHovered ? 0.08 : 0.045),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(isHovered ? 0.15 : 0.08), lineWidth: 1)
        }
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
        .animation(.smooth(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1)) {
                appeared = true
            }
        }
    }
}

private struct SetupDurationCard: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        SetupCard(icon: "timer", title: "Default session", detail: "Start with the duration you use most.") {
            HStack(spacing: 7) {
                ForEach([25, 45, 60], id: \.self) { minutes in
                    Button("\(minutes)m") {
                        viewModel.selectDuration(minutes)
                    }
                    .buttonStyle(SetupChoiceButtonStyle(isSelected: viewModel.selectedDurationMinutes == minutes && !viewModel.isCustomDurationSelected))
                }
            }
        }
    }
}

private struct PermissionSetupCard: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        SetupCard(icon: notificationIcon, title: "Gentle alerts", detail: "Completion and distraction reminders stay optional.") {
            Button(buttonTitle, action: requestNotifications)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .frame(width: 76)
                .disabled(viewModel.notificationAuthorizationStatus == .authorized)
        }
        .task {
            await viewModel.refreshNotificationAuthorizationStatus()
        }
    }

    private var notificationIcon: String {
        switch viewModel.notificationAuthorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "bell.badge.fill"
        case .denied:
            return "bell.slash.fill"
        default:
            return "bell.fill"
        }
    }

    private var buttonTitle: String {
        switch viewModel.notificationAuthorizationStatus {
        case .authorized:
            return "Allowed"
        case .denied:
            return "Denied"
        default:
            return "Enable"
        }
    }

    private func requestNotifications() {
        Task {
            await viewModel.requestNotificationAuthorization()
        }
    }
}

private struct DistractionSetupCard: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        SetupCard(icon: "hand.raised", title: "Distraction apps", detail: "Checked locally during active sessions only.") {
            HStack(spacing: 5) {
                ForEach(viewModel.preferences.distractionAppNames.prefix(3), id: \.self) { name in
                    Text(name)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.08), in: Capsule())
                }
            }
        }
    }
}

private struct SetupCard<Trailing: View>: View {
    let icon: String
    let title: String
    let detail: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(OriloColors.gradientMid, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            trailing
        }
        .padding(11)
        .frame(minHeight: 62)
        .background(OriloColors.surfaceElevated, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(OriloColors.surfaceBorder, lineWidth: 1)
        }
    }
}

private struct SetupChoiceButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 9)
            .frame(height: 28)
            .foregroundStyle(isSelected ? .primary : .secondary)
            .background(
                isSelected
                    ? Color.accentColor.opacity(configuration.isPressed ? 0.16 : 0.11)
                    : Color.secondary.opacity(configuration.isPressed ? 0.10 : 0.06),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(isSelected ? Color.accentColor.opacity(0.42) : Color.secondary.opacity(0.10), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.smooth(duration: 0.12), value: configuration.isPressed)
            .animation(.smooth(duration: 0.16), value: isSelected)
    }
}
