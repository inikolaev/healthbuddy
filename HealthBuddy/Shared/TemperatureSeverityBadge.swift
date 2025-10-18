import SwiftUI

struct TemperatureSeverityBadge: View {
    var severity: TemperatureSeverity?

    var body: some View {
        let guide = severity.map(TemperatureSeverityGuide.guide) ?? TemperatureSeverityGuide.neutral()
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(guide.color.gradient)
                    .frame(width: 12, height: 12)
                Text(guide.title)
                    .font(.headline)
            }
            Text(guide.message)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
