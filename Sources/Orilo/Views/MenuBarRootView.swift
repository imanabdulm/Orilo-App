import AppKit
import SwiftUI

struct MenuBarRootView: View {
    @Bindable var viewModel: FocusViewModel
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    private let panelWidth: CGFloat = 356

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HeaderView(viewModel: viewModel)

            panelContent
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .transaction { transaction in
                    transaction.animation = nil
                }

            if case .completed = viewModel.phase {
                EmptyView()
            } else {
                DailyStatsView(viewModel: viewModel)
            }

            Divider()

            HStack {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "history")
                } label: {
                    Label("Analytics & Insights", systemImage: "chart.bar.xaxis")
                }
                .help("Analytics & Insights")

                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                } label: {
                    Label("Preferences", systemImage: "slider.horizontal.3")
                }
                .help("Preferences")

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                }
                .keyboardShortcut("q")
                .help("Quit Orilo")
            }
            .buttonStyle(.borderless)
            .font(.callout)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: panelWidth, alignment: .topLeading)
    }

    @ViewBuilder
    private var panelContent: some View {
        switch viewModel.phase {
        case .idle:
            StartSessionView(viewModel: viewModel)
        case .settling:
            SettlingView(viewModel: viewModel)
        case .running, .paused:
            ActiveSessionView(viewModel: viewModel)
        case .breakTime:
            BreakTimeView(viewModel: viewModel)
        case .completed(let recap):
            RecapView(viewModel: viewModel, recap: recap)
        }
    }

}
