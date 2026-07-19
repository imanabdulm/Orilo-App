import SwiftUI

struct MilestoneView: View {
    let milestone: Milestone
    let onDismiss: () -> Void

    struct Milestone: Equatable {
        let title: String
        let detail: String
        let systemImage: String
        let value: String
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 64, height: 64)

                Image(systemName: milestone.systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 5) {
                Text(milestone.value)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text(milestone.title)
                    .font(.headline.weight(.semibold))

                Text(milestone.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button { onDismiss() } label: {
                Text("Keep going")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(width: 300)
    }
}
