import SwiftUI

struct StatusBadge: View {
    let isOffline: Bool
    let lastSyncDate: Date?
    let isConnected: Bool
    let isSyncingInBackground: Bool

    @State private var rotationAngle: Double = 0

    var body: some View {
        // Icon-only status indicator with circular style matching settings button
        Group {
            if isSyncingInBackground {
                // Rotating sync indicator
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }
            } else if isOffline {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            } else if isConnected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            } else {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 44, height: 44)
        .background(Color.black.opacity(0.6))
        .clipShape(Circle())
    }

    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}
