import SwiftUI

struct StatusBadge: View {
    let isOffline: Bool
    let lastSyncDate: Date?
    let isConnected: Bool
    let isSyncingInBackground: Bool

    @State private var rotationAngle: Double = 0

    var body: some View {
        HStack(spacing: 6) {
            // Connection status indicator
            if isSyncingInBackground {
                // Rotating sync indicator
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }
            } else {
                Circle()
                    .fill(isOffline ? Color.orange : (isConnected ? Color.green : Color.red))
                    .frame(width: 8, height: 8)
            }

            // Status text
            if isSyncingInBackground {
                Text("Syncing...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if isOffline {
                Text("Offline")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let lastSync = lastSyncDate {
                Text("Synced \(timeAgoString(from: lastSync))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Online")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
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
