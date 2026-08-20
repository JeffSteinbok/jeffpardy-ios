import SwiftUI
import UIKit

struct PlayerView: View {
    @Binding var pendingGameCode: String?
    @StateObject private var viewModel = PlayerViewModel()
    @StateObject private var nearbyBrowser = NearbyGameBrowser()
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasSelectedGame = false
    @State private var isShowingScanner = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isJoined {
                    buzzerView
                } else {
                    joinView
                }
            }
            .navigationTitle("PLAYER")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(JeffpardyTheme.chrome, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert(
                "Jeffpardy",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .toolbar {
                if viewModel.isJoined {
                    if let playerURL = AppConfiguration.playerURL(gameCode: viewModel.gameCode) {
                        ToolbarItem(placement: .topBarLeading) {
                            ShareLink(
                                item: playerURL,
                                subject: Text("Join my Jeffpardy game"),
                                message: Text("Join my Jeffpardy game \(viewModel.gameCode).")
                            ) {
                                Label("Invite", systemImage: "square.and.arrow.up")
                            }
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Leave") {
                            Task {
                                await viewModel.disconnect()
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            nearbyBrowser.start()
            consumePendingGameCode()
        }
        .onDisappear {
            nearbyBrowser.stop()
        }
        .fullScreenCover(isPresented: $isShowingScanner) {
            playerQRScanner
        }
        .onChange(of: pendingGameCode) {
            consumePendingGameCode()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active, viewModel.isJoined else {
                return
            }
            Task {
                await viewModel.join()
            }
        }
    }

    private var joinView: some View {
        ScrollView {
            VStack(spacing: 28) {
                JeffpardyLogo()
                    .frame(maxWidth: 340)
                    .padding(.top, 36)

                Text(hasSelectedGame ? "WHO'S PLAYING?" : "JOIN A GAME")
                    .font(.title.weight(.black))
                    .tracking(2)
                    .shadow(color: .black, radius: 2, x: 2, y: 2)

                if hasSelectedGame {
                    playerDetailsCard
                } else {
                    gameSelectionCard
                }

                Button {
                    if hasSelectedGame {
                        Task {
                            await viewModel.join()
                        }
                    } else {
                        hasSelectedGame = true
                    }
                } label: {
                    if viewModel.connectionState == .connecting {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Label(
                            hasSelectedGame ? "Join Game" : "Continue",
                            systemImage: hasSelectedGame ? "play.fill" : "arrow.right"
                        )
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(JeffpardyPrimaryButtonStyle())
                .frame(maxWidth: 440)
                .disabled(hasSelectedGame ? !viewModel.canJoin : viewModel.gameCode.count != 6)
                .opacity((hasSelectedGame ? viewModel.canJoin : viewModel.gameCode.count == 6) ? 1 : 0.5)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .jeffpardyBackground()
    }

    private var gameSelectionCard: some View {
        JeffpardyCard {
            VStack(spacing: 16) {
                if !nearbyBrowser.games.isEmpty {
                    nearbyGames
                    labeledDivider("OR")
                }

                Button {
                    isShowingScanner = true
                } label: {
                    Label("Scan Player QR Code", systemImage: "qrcode.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(JeffpardyPrimaryButtonStyle())
                .disabled(!QRScannerView.isSupported)
                .opacity(QRScannerView.isSupported ? 1 : 0.5)

                labeledDivider("OR ENTER CODE")
                CodeField(title: "6-character game code", text: $viewModel.gameCode)
            }
        }
        .frame(maxWidth: 440)
    }

    private var playerDetailsCard: some View {
        JeffpardyCard {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("GAME CODE")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.55))
                        Text(viewModel.gameCode)
                            .font(.title2.monospaced().weight(.black))
                    }

                    Spacer()

                    Button("Change") {
                        hasSelectedGame = false
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(JeffpardyTheme.gold)
                }

                Divider()
                    .overlay(.white.opacity(0.15))

                if let playerURL = AppConfiguration.playerURL(gameCode: viewModel.gameCode) {
                    ShareLink(
                        item: playerURL,
                        subject: Text("Join my Jeffpardy game"),
                        message: Text("Join my Jeffpardy game \(viewModel.gameCode).")
                    ) {
                        Label("Invite Friends", systemImage: "square.and.arrow.up")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(JeffpardyTheme.gold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    }

                    Divider()
                        .overlay(.white.opacity(0.15))
                }

                TextField(
                    "",
                    text: $viewModel.team,
                    prompt: Text("Team name").foregroundStyle(.white.opacity(0.55))
                )
                .textInputAutocapitalization(.words)
                .textFieldStyle(JeffpardyTextFieldStyle())

                TextField(
                    "",
                    text: $viewModel.name,
                    prompt: Text("Player name").foregroundStyle(.white.opacity(0.55))
                )
                .textInputAutocapitalization(.words)
                .textFieldStyle(JeffpardyTextFieldStyle())
            }
        }
        .frame(maxWidth: 440)
    }

    private func labeledDivider(_ label: String) -> some View {
        HStack {
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(height: 1)
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.55))
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(height: 1)
        }
    }

    private var playerQRScanner: some View {
        NavigationStack {
            ZStack {
                QRScannerView { payload in
                    guard
                        let url = URL(string: payload),
                        let gameCode = AppConfiguration.gameCode(fromPlayerURL: url)
                    else {
                        viewModel.errorMessage = "Scan a Jeffpardy player QR code."
                        return
                    }

                    selectGame(gameCode)
                    isShowingScanner = false
                }
                .ignoresSafeArea()

                VStack {
                    Spacer()
                    JeffpardyCard {
                        Label("SCAN PLAYER QR CODE", systemImage: "qrcode.viewfinder")
                            .font(.headline.weight(.black))
                            .tracking(0.8)
                    }
                    .padding(24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isShowingScanner = false
                    }
                }
            }
            .toolbarBackground(JeffpardyTheme.chrome, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var nearbyGames: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nearby Games")
                .font(.headline.weight(.black))
                .tracking(0.8)

            ForEach(nearbyBrowser.games) { game in
                Button {
                    selectGame(game.gameCode)
                } label: {
                    HStack {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .foregroundStyle(JeffpardyTheme.gold)

                        VStack(alignment: .leading) {
                            Text(game.hostName)
                                .font(.headline)
                            Text(game.gameCode)
                                .font(.caption.monospaced())
                        }

                        Spacer()

                        if viewModel.gameCode == game.gameCode {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(12)
                    .background(.black.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func selectGame(_ gameCode: String) {
        viewModel.gameCode = gameCode.uppercased()
        hasSelectedGame = true
    }

    private func consumePendingGameCode() {
        guard let pendingGameCode else {
            return
        }

        selectGame(pendingGameCode)
        self.pendingGameCode = nil
    }

    private var buzzerView: some View {
        VStack(spacing: 24) {
            JeffpardyLogo()
                .frame(maxWidth: 280)

            JeffpardyCard {
                HStack {
                    Label(viewModel.connectionState.label, systemImage: connectionIcon)
                    Spacer()
                    Text(viewModel.gameCode.uppercased())
                        .font(.headline.monospaced())
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white.opacity(0.78))
            }

            Spacer()

            Text("\(viewModel.name) • \(viewModel.team)")
                .font(.title2.weight(.black))
                .textCase(.uppercase)
                .tracking(1)
                .shadow(color: .black, radius: 2, x: 2, y: 2)

            Button {
                buzz()
            } label: {
                VStack(spacing: 8) {
                    Text(viewModel.buzzerState.label)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.5)

                    if case let .winner(_, team, reactionTime) = viewModel.buzzerState {
                        Text("\(team) • \(reactionTime) ms")
                            .font(.headline)
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 270, height: 270)
                .background(
                    RadialGradient(
                        colors: [buzzerColor.opacity(0.95), buzzerColor.opacity(0.48)],
                        center: .topLeading,
                        startRadius: 10,
                        endRadius: 260
                    )
                )
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.9), JeffpardyTheme.gold.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 8
                        )
                }
                .shadow(color: .black.opacity(0.55), radius: 14, y: 10)
                .shadow(color: buzzerColor.opacity(0.65), radius: 26)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Jeffpardy buzzer")
            .accessibilityHint("Tap when the buzzer turns green")

            Text(buzzerHelp)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
                .frame(minHeight: 44)

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .jeffpardyBackground()
    }

    private var buzzerColor: Color {
        switch viewModel.buzzerState {
        case .inactive:
            JeffpardyTheme.inactive
        case .ready:
            .green
        case .submitted:
            JeffpardyTheme.gold
        case .locked:
            .red
        case .winner:
            .purple
        }
    }

    private var buzzerHelp: String {
        switch viewModel.buzzerState {
        case .inactive:
            "Wait for the buzzer to activate."
        case .ready:
            "Tap now!"
        case .submitted:
            "Buzz sent. Waiting for the result."
        case .locked:
            "Too early. Try again when the buzzer turns green."
        case let .winner(name, _, _):
            "\(name) buzzed first."
        }
    }

    private var connectionIcon: String {
        switch viewModel.connectionState {
        case .connected:
            "wifi"
        case .connecting, .reconnecting:
            "arrow.triangle.2.circlepath"
        case .disconnected:
            "wifi.slash"
        }
    }

    private func buzz() {
        let feedback = UIImpactFeedbackGenerator(style: .heavy)
        feedback.impactOccurred()
        Task {
            await viewModel.buzz()
        }
    }
}

#Preview {
    PlayerView(pendingGameCode: .constant(nil))
}
