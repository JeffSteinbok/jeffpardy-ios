import SwiftUI

struct RootView: View {
    private enum AppTab: Hashable {
        case player
        case hostDisplay
    }

    @State private var selectedTab = AppTab.player
    @State private var pendingGameCode: String?

    var body: some View {
        TabView(selection: $selectedTab) {
            PlayerView(pendingGameCode: $pendingGameCode)
                .tabItem {
                    Label("Player", systemImage: "hand.tap")
                }
                .tag(AppTab.player)

            HostSecondaryView()
                .tabItem {
                    Label("Host Display", systemImage: "tv")
                }
                .tag(AppTab.hostDisplay)
        }
        .tint(JeffpardyTheme.gold)
        .toolbarBackground(JeffpardyTheme.chrome, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .onOpenURL { url in
            guard let gameCode = AppConfiguration.gameCode(fromPlayerURL: url) else {
                return
            }

            pendingGameCode = gameCode
            selectedTab = .player
        }
    }
}

#Preview {
    RootView()
}
