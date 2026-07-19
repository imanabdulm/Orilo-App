import AppKit
import SwiftUI

/// Presents a gentle full-screen "focus shield" overlay above other apps when a
/// distraction is detected during a session. It nudges (and can hide the
/// distracting app) without force-quitting anything.
@MainActor
final class DistractionOverlayController {
    private var window: NSWindow?

    var isVisible: Bool { window != nil }

    func present(
        appName: String,
        intention: String,
        onHide: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        onSnooze: (() -> Void)? = nil
    ) {
        guard window == nil else { return }

        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        let overlay = NSWindow(
            contentRect: screenFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        overlay.isOpaque = false
        overlay.backgroundColor = .clear
        overlay.level = .screenSaver
        overlay.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        overlay.hasShadow = false
        overlay.isReleasedWhenClosed = false
        overlay.ignoresMouseEvents = false

        let root = DistractionOverlayView(
            appName: appName,
            intention: intention,
            onHide: { [weak self] in
                self?.dismiss()
                onHide()
            },
            onDismiss: { [weak self] in
                self?.dismiss()
                onDismiss()
            },
            onSnooze: onSnooze != nil ? { [weak self] in
                self?.dismiss()
                onSnooze?()
            } : nil
        )

        let hosting = NSHostingView(rootView: root)
        hosting.frame = NSRect(origin: .zero, size: screenFrame.size)
        overlay.contentView = hosting
        overlay.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        window = overlay
    }

    func dismiss() {
        window?.orderOut(nil)
        window = nil
    }
}

private struct DistractionOverlayView: View {
    let appName: String
    let intention: String
    let onHide: () -> Void
    let onDismiss: () -> Void
    let onSnooze: (() -> Void)?

    @State private var appeared = false
    @State private var keepGoingCountdown = 4

    private let keepGoingDelay = 4
    private let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var canKeepGoing: Bool { keepGoingCountdown <= 0 }

    private var accentGradient: LinearGradient { OriloColors.primaryGradient }

    var body: some View {
        ZStack {
            Color.black.opacity(0.34)
                .ignoresSafeArea()

            card
                .scaleEffect(appeared ? 1 : 0.92)
                .opacity(appeared ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(countdownTimer) { _ in
            if keepGoingCountdown > 0 {
                keepGoingCountdown -= 1
            }
        }
        .onAppear {
            keepGoingCountdown = keepGoingDelay
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }

    private var card: some View {
        VStack(spacing: 22) {
            iconBadge

            VStack(spacing: 9) {
                Text("Come back to your focus")
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .multilineTextAlignment(.center)

                Text("\(appName) is pulling you away.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            intentionChip

            buttons
        }
        .padding(.horizontal, 30)
        .padding(.top, 30)
        .padding(.bottom, 24)
        .frame(width: 440)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), Color.white.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.40), radius: 40, y: 18)
    }

    private var iconBadge: some View {
        Group {
            if let appIcon = NSApp.applicationIconImage {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                // Fallback — should never happen in a running .app bundle.
                Image(systemName: "moon.stars.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(accentGradient))
            }
        }
        .frame(width: 76, height: 76)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .shadow(color: OriloColors.gradientMid.opacity(0.30), radius: 14, y: 6)
    }

    private var intentionChip: some View {
        HStack(spacing: 7) {
            Image(systemName: "flag.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(intention)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.secondary.opacity(0.08), in: Capsule())
        .overlay {
            Capsule().strokeBorder(.secondary.opacity(0.15), lineWidth: 1)
        }
    }

    private var buttons: some View {
        HStack(spacing: 12) {
            Button(action: onDismiss) {
                Text(canKeepGoing ? "Keep going" : "Keep going (\(keepGoingCountdown))")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.plain)
            .disabled(!canKeepGoing)
            .opacity(canKeepGoing ? 1 : 0.5)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
            }
            .animation(.smooth(duration: 0.2), value: canKeepGoing)

            Button(action: onHide) {
                Text("Hide \(appName)")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.plain)
            .background(Color(red: 0, green: 122 / 255, blue: 1.0), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color(red: 0, green: 122 / 255, blue: 1.0).opacity(0.35), radius: 10, y: 4)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.top, 4)
    }
}
