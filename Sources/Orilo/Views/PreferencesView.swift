import AppKit
import Observation
import SwiftUI

struct PreferencesView: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        TabView {
            GeneralPreferencesPane(viewModel: viewModel)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            SessionPreferencesPane(viewModel: viewModel)
                .tabItem {
                    Label("Session", systemImage: "timer")
                }

            DistractionsPreferencesPane(viewModel: viewModel)
                .tabItem {
                    Label("Distractions", systemImage: "hand.raised")
                }
        }
        .padding(24)
        .frame(width: 620, height: 460)
        .onAppear {
            viewModel.refreshRunningApps()
            viewModel.refreshAccessibilityTrust()
            Task {
                await viewModel.refreshNotificationAuthorizationStatus()
            }
        }
    }
}

private struct GeneralPreferencesPane: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        PreferencePane(title: "General", subtitle: "Keep Orilo quiet and available.") {
            PreferenceRow(
                title: "Launch at login",
                detail: "Start Orilo automatically when you sign in."
            ) {
                Toggle(
                    "Launch at login",
                    isOn: Binding(
                        get: { viewModel.preferences.launchAtLoginEnabled },
                        set: { viewModel.setLaunchAtLoginEnabled($0) }
                    )
                )
                .labelsHidden()
            }

            if let message = viewModel.launchAtLoginErrorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Divider()

            PreferenceRow(
                title: "Sound effects",
                detail: "Play quiet system sounds for start, pause, completion, and breaks."
            ) {
                HStack(spacing: 8) {
                    Button {
                        viewModel.playSoundPreview()
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.borderless)
                    .disabled(!viewModel.preferences.soundEnabled)
                    .help("Preview sound")

                    Toggle(
                        "Sound effects",
                        isOn: Binding(
                            get: { viewModel.preferences.soundEnabled },
                            set: {
                                viewModel.preferences.soundEnabled = $0
                                viewModel.persistPreferences()
                            }
                        )
                    )
                    .labelsHidden()
                }
            }

            Divider()

            PreferenceRow(
                title: "Appearance",
                detail: "Follow the system, or keep Orilo fixed in one mode."
            ) {
                Picker("Appearance", selection: Binding(
                    get: { viewModel.preferences.appearance },
                    set: {
                        viewModel.preferences.appearance = $0
                        viewModel.persistPreferences()
                    }
                )) {
                    ForEach(AppPreferences.Appearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 210)
            }

            Divider()

            PreferenceRow(
                title: "Support Orilo",
                detail: "Help fund Apple Developer Program notarization ($99/year)."
            ) {
                Link(destination: URL(string: "https://ko-fi.com/imanabdul")!) {
                    Label("Support on Ko-fi", systemImage: "cup.and.saucer.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 255/255, green: 94/255, blue: 91/255))
            }
        }
    }
}

private struct SessionPreferencesPane: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        PreferencePane(title: "Session", subtitle: "Tune how a focus ritual starts and ends.", scrollable: true) {
            PreferenceRow(
                title: "Custom duration",
                detail: "Used by the Custom preset in the menu bar panel."
            ) {
                CustomDurationControl(viewModel: viewModel)
            }

            Divider()

            PreferenceRow(
                title: "Pomodoro rhythm",
                detail: "Start a break automatically after a completed countdown."
            ) {
                Toggle(
                    "Pomodoro rhythm",
                    isOn: Binding(
                        get: { viewModel.preferences.pomodoroEnabled },
                        set: {
                            viewModel.preferences.pomodoroEnabled = $0
                            viewModel.persistPreferences()
                        }
                    )
                )
                .labelsHidden()
            }

            if viewModel.preferences.pomodoroEnabled {
                PomodoroBreakControls(viewModel: viewModel)
                    .padding(.top, 4)
                    .padding(.bottom, 12)
            }

            Divider()

            PreferenceRow(
                title: "Focus fallback",
                detail: "Open macOS Focus settings when a session starts."
            ) {
                Toggle(
                    "Open Focus settings",
                    isOn: Binding(
                        get: { viewModel.preferences.openFocusSettingsOnStart },
                        set: {
                            viewModel.preferences.openFocusSettingsOnStart = $0
                            viewModel.persistPreferences()
                        }
                    )
                )
                .labelsHidden()
            }

            Divider()

            PreferenceRow(
                title: "Completion notification",
                detail: "Send a local notification when the countdown ends."
            ) {
                Toggle(
                    "Completion notification",
                    isOn: Binding(
                        get: { viewModel.preferences.completionNotificationsEnabled },
                        set: {
                            viewModel.preferences.completionNotificationsEnabled = $0
                            viewModel.persistPreferences()
                        }
                    )
                )
                .labelsHidden()
            }

            PreferenceRow(
                title: "Distraction reminder",
                detail: "Rate-limited local reminder while a listed app is frontmost."
            ) {
                Toggle(
                    "Distraction reminder",
                    isOn: Binding(
                        get: { viewModel.preferences.distractionNotificationsEnabled },
                        set: {
                            viewModel.preferences.distractionNotificationsEnabled = $0
                            viewModel.persistPreferences()
                        }
                    )
                )
                .labelsHidden()
            }

            Divider()

            PreferenceRow(
                title: "Notification permission",
                detail: "Required for completion alerts and distraction reminders."
            ) {
                NotificationPermissionControl(viewModel: viewModel)
            }

            Divider()

            PreferenceRow(
                title: "Weekend streak freeze",
                detail: "Keep your streak active across Saturdays and Sundays."
            ) {
                Toggle(
                    "Weekend streak freeze",
                    isOn: Binding(
                        get: { viewModel.preferences.excludeWeekendsFromStreak },
                        set: {
                            viewModel.preferences.excludeWeekendsFromStreak = $0
                            viewModel.persistPreferences()
                        }
                    )
                )
                .labelsHidden()
            }
        }
    }
}

private struct PomodoroBreakControls: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        VStack(spacing: 8) {
            PreferenceRow(
                title: "Short break",
                detail: "Break after each completed focus ritual."
            ) {
                CapsuleStepper(
                    value: Binding(
                        get: { viewModel.preferences.breakDurationMinutes },
                        set: {
                            viewModel.preferences.breakDurationMinutes = $0
                            viewModel.persistPreferences()
                        }
                    ),
                    range: 1...30,
                    step: 1,
                    suffix: "m",
                    label: "short break"
                )
            }

            PreferenceRow(
                title: "Long break",
                detail: "Longer reset after several completed sessions."
            ) {
                CapsuleStepper(
                    value: Binding(
                        get: { viewModel.preferences.longBreakDurationMinutes },
                        set: {
                            viewModel.preferences.longBreakDurationMinutes = $0
                            viewModel.persistPreferences()
                        }
                    ),
                    range: 5...60,
                    step: 5,
                    suffix: "m",
                    label: "long break"
                )
            }

            PreferenceRow(
                title: "Long break after",
                detail: "How many completed sessions before the long break."
            ) {
                CapsuleStepper(
                    value: Binding(
                        get: { viewModel.preferences.sessionsBeforeLongBreak },
                        set: {
                            viewModel.preferences.sessionsBeforeLongBreak = $0
                            viewModel.persistPreferences()
                        }
                    ),
                    range: 2...8,
                    step: 1,
                    label: "long break threshold"
                )
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.045), in: RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct DistractionsPreferencesPane: View {
    @Bindable var viewModel: FocusViewModel
    @State private var newDistractionApp = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        PreferencePane(title: "Distractions", subtitle: "Name apps that should trigger a gentle check-in.", scrollable: true) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Add an app")
                    .font(.headline.weight(.medium))

                HStack(spacing: 9) {
                    Image(systemName: "app.badge")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 22, height: 22)

                    TextField("App name or bundle ID", text: $newDistractionApp)
                        .textFieldStyle(.plain)
                        .focused($isInputFocused)
                        .onSubmit(addDistraction)

                    Button {
                        addDistraction()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .disabled(newDistractionApp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help("Add distraction app")
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .frame(minHeight: 40)
                .background(
                    (isInputFocused ? Color.accentColor.opacity(0.08) : Color.secondary.opacity(0.07)),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isInputFocused ? Color.accentColor.opacity(0.82) : Color.secondary.opacity(0.12),
                            lineWidth: isInputFocused ? 1.5 : 1
                        )
                }
                .shadow(color: isInputFocused ? Color.accentColor.opacity(0.18) : .clear, radius: 6, y: 1)

                HStack {
                    Text("Detects standalone apps when they come to the front. Sites opened inside a browser (e.g. YouTube) aren't matched — add the browser app instead. Bundle IDs like com.apple.Safari are the most precise.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    RunningAppsMenu(viewModel: viewModel)
                }

                VStack(spacing: 10) {
                    AccessibilityPermissionControl(viewModel: viewModel)

                    FocusShieldControl(viewModel: viewModel)
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick presets")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Button("+ Social Media") {
                            ["Safari", "Slack", "Discord", "Messages", "Telegram"].forEach { viewModel.addDistractionApp(named: $0) }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button("+ Video & Stream") {
                            ["Safari", "Arc", "Chrome", "YouTube"].forEach { viewModel.addDistractionApp(named: $0) }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button("+ Games") {
                            ["Steam", "Epic Games"].forEach { viewModel.addDistractionApp(named: $0) }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.top, 6)
            }
            .padding(.top, 6)
            .padding(.bottom, 26)

            VStack(alignment: .leading, spacing: 14) {
                Text("Reminder list")
                    .font(.headline.weight(.medium))

                Group {
                    if viewModel.preferences.distractionAppNames.isEmpty {
                        EmptyDistractionsView()
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.preferences.distractionAppNames.enumerated()), id: \.element) { index, name in
                                DistractionAppRow(name: name) {
                                    removeDistraction(named: name)
                                }

                                if index < viewModel.preferences.distractionAppNames.count - 1 {
                                    Divider()
                                        .padding(.leading, 44)
                                        .padding(.trailing, 10)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .frame(minHeight: 146)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                }
            }
            .padding(.bottom, 10)
        }
        .animation(.smooth(duration: 0.16), value: isInputFocused)
    }

    private func addDistraction() {
        viewModel.addDistractionApp(named: newDistractionApp)
        newDistractionApp = ""
    }

    private func removeDistraction(named name: String) {
        guard let index = viewModel.preferences.distractionAppNames.firstIndex(of: name) else {
            return
        }

        viewModel.removeDistractionApps(at: IndexSet(integer: index))
    }
}

private struct RunningAppsMenu: View {
    @Bindable var viewModel: FocusViewModel
    @State private var isPresented = false

    var body: some View {
        Button {
            viewModel.refreshRunningApps()
            isPresented.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "macwindow")
                Text("Running Apps")
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.bordered)
        .fixedSize()
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                PopoverActionRow(title: "Refresh apps", systemImage: "arrow.clockwise") {
                    viewModel.refreshRunningApps()
                }

                Divider()
                    .padding(.vertical, 2)

                if viewModel.runningApps.isEmpty {
                    Text("No running apps found")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(viewModel.runningApps) { app in
                                PopoverActionRow(title: app.name, systemImage: nil) {
                                    viewModel.addDistractionApp(app)
                                    isPresented = false
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 240)
                }
            }
            .padding(6)
            .frame(width: 230)
        }
    }
}

private struct PopoverActionRow: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .frame(width: 16)
                }
                Text(title)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
            .background(
                isHovering ? Color.primary.opacity(0.08) : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

private struct FocusShieldControl: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "shield.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(viewModel.preferences.distractionOverlayEnabled ? Color.accentColor : Color.secondary)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text("Focus shield")
                    .font(.caption.weight(.semibold))
                Text("Show a full-screen nudge over a distraction during a session, with a button to hide it.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Toggle(
                "Focus shield",
                isOn: Binding(
                    get: { viewModel.preferences.distractionOverlayEnabled },
                    set: {
                        viewModel.preferences.distractionOverlayEnabled = $0
                        viewModel.persistPreferences()
                    }
                )
            )
            .labelsHidden()
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.11), lineWidth: 1)
        }
    }
}

private struct AccessibilityPermissionControl: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: viewModel.accessibilityTrusted ? "checkmark.shield.fill" : "shield.lefthalf.filled")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(viewModel.accessibilityTrusted ? Color.green : Color.orange)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text("Browser tab detection")
                    .font(.caption.weight(.semibold))
                Text(viewModel.accessibilityTrusted
                    ? "Accessibility is on — web distractions like YouTube are detected."
                    : "Click Enable, then turn on Orilo in System Settings → Accessibility.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if viewModel.accessibilityTrusted {
                Button {
                    viewModel.refreshAccessibilityTrust()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderless)
                .help("Refresh accessibility permission")
            } else {
                Button("Enable") {
                    // macOS requires the user to flip the toggle themselves — an
                    // app can't grant itself Accessibility. This prompt registers
                    // Orilo in the list and offers an "Open System Settings" button.
                    viewModel.requestAccessibilityPermission()
                }
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.11), lineWidth: 1)
        }
        .onReceive(Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()) { _ in
            viewModel.refreshAccessibilityTrust()
        }
    }
}

private struct NotificationPermissionControl: View {
    @Bindable var viewModel: FocusViewModel

    var body: some View {
        HStack(spacing: 8) {
            NotificationStatusBadge(status: viewModel.notificationAuthorizationStatus)

            switch viewModel.notificationAuthorizationStatus {
            case .notDetermined:
                Button("Allow") {
                    Task {
                        await viewModel.requestNotificationAuthorization()
                    }
                }
            case .denied:
                Button("Open Settings") {
                    openNotificationSettings()
                }
            case .authorized, .provisional, .ephemeral, .unknown:
                Button {
                    Task {
                        await viewModel.refreshNotificationAuthorizationStatus()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderless)
                .help("Refresh notification permission")
            }
        }
        .fixedSize()
    }

    private func openNotificationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}

private struct NotificationStatusBadge: View {
    let status: NotificationService.AuthorizationStatus

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(status.title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.secondary.opacity(0.07), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.secondary.opacity(0.11), lineWidth: 1)
        }
    }

    private var color: Color {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return .green
        case .denied:
            return .orange
        case .notDetermined, .unknown:
            return .secondary.opacity(0.7)
        }
    }
}

private struct DistractionAppRow: View {
    let name: String
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "app.dashed")
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(name)
                .font(.callout)
                .lineLimit(1)

            Spacer(minLength: 8)

            Button(role: .destructive, action: remove) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Remove \(name)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(minHeight: 40)
    }
}

private struct EmptyDistractionsView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.raised")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.secondary)

            Text("No protected boundaries yet")
                .font(.subheadline.weight(.medium))

            Text("Add the apps that pull you away. Orilo only checks them during active sessions.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 146)
        .padding(.horizontal, 24)
        .background(.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct PreferencePane<Content: View>: View {
    let title: String
    let subtitle: String
    var scrollable: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.weight(.medium))
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if scrollable {
                ScrollView {
                    card
                }
            } else {
                card
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.secondary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct PreferenceRow<Control: View>: View {
    let title: String
    let detail: String
    @ViewBuilder var control: Control

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 20)

            control
                .frame(width: 204, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .frame(minHeight: 52)
    }
}
