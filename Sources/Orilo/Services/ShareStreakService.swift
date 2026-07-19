import AppKit
import SwiftUI

/// Generates a shareable streak card image for Orilo and opens the share sheet.
struct ShareStreakService {

    struct StreakCardData {
        let streakDays: Int
        let totalSessions: Int
        let focusedMinutes: Int
        let topIntention: String?
    }

    @MainActor
    static func generateAndShare(data: StreakCardData) {
        let cardView = StreakCard(data: data)
        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 2.0
        renderer.proposedSize = ProposedViewSize(width: 800, height: 420)

        guard let image = renderer.nsImage else { return }

        let picker = NSSharingServicePicker(items: [image])
        if let window = NSApp.keyWindow {
            picker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
        }
    }
}

// MARK: - Streak Card View (rendered to image)

private struct StreakCard: View {
    let data: ShareStreakService.StreakCardData

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hue: 0.72, saturation: 0.55, brightness: 0.18),
                    Color(hue: 0.65, saturation: 0.65, brightness: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.03))
                .frame(width: 380, height: 380)
                .offset(x: 260, y: -80)

            Circle()
                .fill(Color.white.opacity(0.03))
                .frame(width: 240, height: 240)
                .offset(x: -140, y: 140)

            // Content
            HStack(spacing: 0) {
                // Left: streak number
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.orange)

                        Text("Orilo")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Text("\(data.streakDays)")
                        .font(.system(size: 120, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Text(data.streakDays == 1 ? "day streak" : "day streak")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 56)

                // Right: stats
                VStack(alignment: .trailing, spacing: 20) {
                    Spacer()

                    CardStatRow(label: "Sessions", value: "\(data.totalSessions)")
                    CardStatRow(label: "Focus time", value: "\(data.focusedMinutes)m")

                    if let intention = data.topIntention {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Working on")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                            Text(intention)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(2)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 200)
                        }
                    }

                    Spacer()

                    Text("Protect one outcome.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                        .italic()
                }
                .padding(.trailing, 56)
            }
        }
        .frame(width: 800, height: 420)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

private struct CardStatRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
    }
}
