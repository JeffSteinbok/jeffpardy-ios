import SwiftUI
import UIKit
import AudioToolbox

struct PlayerView: View {
    @Binding var pendingGameCode: String?
    let onExit: () -> Void
    @StateObject private var viewModel = PlayerViewModel()
    @StateObject private var nearbyBrowser = NearbyGameBrowser()
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasSelectedGame = false
    @State private var isShowingScanner = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isJoined {
                    if viewModel.isGameOver {
                        gameOverView
                    } else if viewModel.finalPhase == .inactive {
                        buzzerView
                    } else {
                        finalJeffpardyView
                    }
                } else {
                    joinView
                }
            }
            .navigationTitle("")
            .toolbarBackground(.hidden, for: .navigationBar)
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
                    } else {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                Task {
                                    await viewModel.disconnect()
                                    onExit()
                                }
                            } label: {
                                Label("Home", systemImage: "chevron.left")
                            }
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Leave") {
                            Task {
                                await viewModel.disconnect()
                                hasSelectedGame = false
                            }
                        }
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            if hasSelectedGame {
                                Task {
                                    await viewModel.disconnect()
                                    hasSelectedGame = false
                                }
                            } else {
                                onExit()
                            }
                        } label: {
                            Label(
                                hasSelectedGame ? "Game Code" : "Home",
                                systemImage: "chevron.left"
                            )
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
            guard newPhase == .active, !viewModel.gameCode.isEmpty else {
                return
            }
            Task {
                await viewModel.resumeConnection()
            }
        }
        .onChange(of: viewModel.winnerFeedbackToken) {
            guard viewModel.winnerFeedbackToken > 0 else {
                return
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            AudioServicesPlaySystemSound(1025)
        }
    }

    private var joinView: some View {
        ScrollView {
            VStack(spacing: 28) {
                JeffpardyLogo()
                    .frame(maxWidth: 300)
                    .padding(.top, 16)

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
                        selectGame(viewModel.gameCode)
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
                nearbyGames
                labeledDivider("OR")

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
                        Task {
                            await viewModel.disconnect()
                            hasSelectedGame = false
                        }
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(JeffpardyTheme.gold)
                }

                Divider()
                    .overlay(.white.opacity(0.15))

                lobbyRoster

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

                if !viewModel.sortedTeams.isEmpty {
                    Menu {
                        ForEach(viewModel.sortedTeams, id: \.name) { team in
                            Button(team.name) {
                                viewModel.team = team.name
                            }
                        }
                    } label: {
                        Label("Choose an existing team", systemImage: "chevron.down")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(JeffpardyTheme.gold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

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
                    .foregroundStyle(.white)
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
            Text("JOIN A NEARBY GAME")
                .font(.headline.weight(.black))
                .tracking(0.8)

            if nearbyBrowser.games.isEmpty {
                Label("No nearby games found", systemImage: "dot.radiowaves.left.and.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.42))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.black.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityAddTraits(.isStaticText)
            } else {
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
                                    .font(.caption)
                                    .tracking(1)
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
    }

    private func selectGame(_ gameCode: String) {
        let normalizedCode = gameCode.uppercased()
        viewModel.gameCode = normalizedCode
        hasSelectedGame = true
        Task {
            await viewModel.connectToLobby(gameCode: normalizedCode)
        }
    }

    private func consumePendingGameCode() {
        guard let pendingGameCode else {
            return
        }

        selectGame(pendingGameCode)
        self.pendingGameCode = nil
    }

    private var lobbyRoster: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CURRENT PLAYERS")
                    .font(.caption.weight(.black))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.65))

                Spacer()

                Label(
                    viewModel.connectionState.label,
                    systemImage: connectionIcon
                )
                .font(.caption.weight(.bold))
                .foregroundStyle(
                    viewModel.connectionState == .connected
                        ? Color.green
                        : Color.white.opacity(0.6)
                )
            }

            if viewModel.sortedTeams.isEmpty {
                Text(
                    lobbyStatusMessage
                )
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
            } else {
                ForEach(viewModel.sortedTeams, id: \.name) { team in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(team.name)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(JeffpardyTheme.gold)
                        Text(team.players.map(\.name).joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.78))
                    }
                }
            }
        }
    }

    private var lobbyStatusMessage: String {
        switch viewModel.connectionState {
        case .connected:
            "No players have joined yet."
        case .connecting, .reconnecting:
            "Reconnecting to the game..."
        case .disconnected:
            "Disconnected. Return to the game-code screen or try again."
        }
    }

    private var buzzerView: some View {
        GeometryReader { geometry in
            if geometry.size.width > geometry.size.height {
                VStack(spacing: 10) {
                    buzzerHeader
                    HStack(alignment: .top, spacing: 20) {
                        buzzerControls
                            .frame(maxWidth: .infinity)
                        playerScoreboard
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        buzzerHeader
                        buzzerControls
                        playerScoreboard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .jeffpardyBackground()
    }

    private var buzzerHeader: some View {
        HStack(spacing: 16) {
            JeffpardyLogo()
                .frame(maxWidth: 180)

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Label(viewModel.connectionState.label, systemImage: connectionIcon)
                    .foregroundStyle(
                        viewModel.connectionState == .connected
                            ? Color.green
                            : Color.white.opacity(0.65)
                    )
                Text(viewModel.gameCode.uppercased())
                    .font(.headline.weight(.black))
                    .tracking(1.5)
                    .foregroundStyle(JeffpardyTheme.gold)
            }
            .font(.caption.weight(.bold))
        }
    }

    private var buzzerControls: some View {
        VStack(spacing: 10) {
            Text("\(viewModel.name) • \(viewModel.team)")
                .font(.headline.weight(.black))
                .textCase(.uppercase)
                .tracking(0.8)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Button {
                buzz()
            } label: {
                VStack(spacing: 6) {
                    Text(viewModel.buzzerState.label)
                        .font(.system(size: 38, weight: .black))
                        .minimumScaleFactor(0.5)

                    if case let .winner(_, team, reactionTime) = viewModel.buzzerState {
                        Text("\(team) • \(reactionTime) ms")
                            .font(.subheadline.weight(.bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 210, height: 210)
                .background(
                    RadialGradient(
                        colors: [buzzerColor.opacity(0.95), buzzerColor.opacity(0.48)],
                        center: .topLeading,
                        startRadius: 10,
                        endRadius: 210
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
                            lineWidth: 7
                        )
                }
                .shadow(color: .black.opacity(0.55), radius: 12, y: 8)
                .shadow(color: buzzerColor.opacity(0.55), radius: 20)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Jeffpardy buzzer")
            .accessibilityHint("Tap when the buzzer turns green")

            Text(buzzerHelp)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
                .frame(minHeight: 36)

            Picker("Handicap", selection: $viewModel.handicap) {
                ForEach(Array(stride(from: 0, through: 300, by: 50)), id: \.self) { value in
                    Text("\(value) ms").tag(value)
                }
            }
            .pickerStyle(.menu)
            .tint(JeffpardyTheme.gold)
        }
    }

    private var playerScoreboard: some View {
        JeffpardyCard {
            VStack(alignment: .leading, spacing: 7) {
                Text(viewModel.isGameOver ? "FINAL SCORES" : "SCORES")
                    .font(.subheadline.weight(.black))
                    .tracking(1)

                if viewModel.sortedTeams.isEmpty {
                    Text("Waiting for other players...")
                        .foregroundStyle(.white.opacity(0.6))
                } else {
                    ForEach(
                        Array(viewModel.sortedTeams.enumerated()),
                        id: \.element.name
                    ) { index, team in
                        HStack(spacing: 8) {
                            if viewModel.isGameOver && index == 0 {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(JeffpardyTheme.gold)
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text(team.name)
                                    .font(.subheadline.weight(.black))
                                Text(team.players.map(\.name).joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.65))
                            }

                            Spacer()

                            Text((viewModel.scores[team.name] ?? 0).formatted())
                                .font(.headline.monospacedDigit().weight(.black))
                                .foregroundStyle(JeffpardyTheme.gold)
                        }

                        if index < viewModel.sortedTeams.count - 1 {
                            Divider()
                                .overlay(.white.opacity(0.12))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: 520)
    }

    private var finalJeffpardyView: some View {
        ScrollView {
            VStack(spacing: 14) {
                buzzerHeader

                Text("FINAL JEFFPARDY")
                    .font(.title2.weight(.black))
                    .tracking(1.5)

                JeffpardyCard {
                    VStack(spacing: 14) {
                        Text("\(viewModel.name) • \(viewModel.team)")
                            .font(.headline.weight(.black))

                        if viewModel.finalWager == nil {
                            Text("ENTER YOUR WAGER")
                                .font(.headline.weight(.black))
                            Text("You may wager from 0 to \(viewModel.finalMaxWager.formatted()).")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))

                            TextField(
                                "",
                                text: $viewModel.finalWagerText,
                                prompt: Text("Wager").foregroundStyle(.white.opacity(0.55))
                            )
                            .keyboardType(.numberPad)
                            .textFieldStyle(JeffpardyTextFieldStyle())

                            Button("Submit Wager") {
                                Task {
                                    await viewModel.submitFinalWager()
                                }
                            }
                            .buttonStyle(JeffpardyPrimaryButtonStyle())
                        } else {
                            Label(
                                "Wager locked: \(viewModel.finalWager?.formatted() ?? "0")",
                                systemImage: "lock.fill"
                            )
                            .font(.headline.weight(.bold))
                            .foregroundStyle(JeffpardyTheme.gold)
                        }

                        Divider()
                            .overlay(.white.opacity(0.15))

                        if viewModel.finalPhase == .wager {
                            Text("Waiting for the host to reveal the clue.")
                                .foregroundStyle(.white.opacity(0.7))
                        } else if viewModel.isFinalResponseSubmitted {
                            Label("Response submitted", systemImage: "checkmark.circle.fill")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.green)
                        } else if viewModel.finalPhase == .ended {
                            Text("Response time has ended.")
                                .font(.headline.weight(.bold))
                        } else {
                            Text("ENTER YOUR RESPONSE")
                                .font(.headline.weight(.black))

                            TextField(
                                "",
                                text: $viewModel.finalResponse,
                                prompt: Text("What is...").foregroundStyle(.white.opacity(0.55))
                            )
                            .textInputAutocapitalization(.sentences)
                            .textFieldStyle(JeffpardyTextFieldStyle())

                            Button("Submit Response") {
                                Task {
                                    await viewModel.submitFinalResponse()
                                }
                            }
                            .buttonStyle(JeffpardyPrimaryButtonStyle())
                        }
                    }
                }
                .frame(maxWidth: 520)

                playerScoreboard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .jeffpardyBackground()
    }

    private var gameOverView: some View {
        VStack(spacing: 24) {
            buzzerHeader

            Spacer()

            Text("FINAL SCORES")
                .font(.title.weight(.black))
                .tracking(1.5)

            playerScoreboard

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
    PlayerView(pendingGameCode: .constant(nil), onExit: {})
}
