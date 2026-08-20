import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HostSecondaryView()
                .tabItem {
                    Label("Host Display", systemImage: "tv")
                }

            PlayerView()
                .tabItem {
                    Label("Player", systemImage: "hand.tap")
                }
        }
        .tint(JeffpardyTheme.gold)
    }
}

#Preview {
    RootView()
}

