import SwiftUI

struct HostSecondaryView: View {
    @State private var gameCode = ""
    @State private var hostCode = ""
    @State private var displayURL: URL?
    @StateObject private var nearbyAdvertiser = NearbyGameAdvertiser()

    var body: some View {
        NavigationStack {
            Group {
                if let displayURL {
                    WebView(url: displayURL)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    setupView
                }
            }
            .navigationTitle("Host Display")
            .toolbar {
                if displayURL != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Change Codes") {
                            nearbyAdvertiser.stop()
                            displayURL = nil
                        }
                    }
                }
            }
        }
    }

    private var setupView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tv")
                .font(.system(size: 64))
                .foregroundStyle(JeffpardyTheme.gold)

            Text("Secondary Window")
                .font(.largeTitle.bold())

            Text("Enter the game and host codes shown by the host.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))

            VStack(spacing: 12) {
                CodeField(title: "6-character game code", text: $gameCode)
                CodeField(title: "6-character host code", text: $hostCode)
            }
            .frame(maxWidth: 420)

            Button("Open Display") {
                displayURL = AppConfiguration.hostSecondaryURL(
                    gameCode: gameCode,
                    hostCode: hostCode
                )
                nearbyAdvertiser.start(gameCode: gameCode)
            }
            .buttonStyle(.borderedProminent)
            .tint(JeffpardyTheme.gold)
            .foregroundStyle(.black)
            .disabled(gameCode.count != 6 || hostCode.count != 6)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .jeffpardyBackground()
    }
}

#Preview {
    HostSecondaryView()
}
