import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            PlayerView()
                .tabItem {
                    Label("Player", systemImage: "hand.tap")
                }

            HostSecondaryView()
                .tabItem {
                    Label("Host Display", systemImage: "tv")
                }
        }
        .tint(JeffpardyTheme.gold)
        .toolbarBackground(JeffpardyTheme.chrome, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}

#Preview {
    RootView()
}
