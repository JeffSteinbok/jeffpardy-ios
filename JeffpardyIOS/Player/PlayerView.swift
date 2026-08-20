import SwiftUI
import UIKit

struct PlayerView: View {
    @StateObject private var viewModel = PlayerViewModel()
    @StateObject private var nearbyBrowser = NearbyGameBrowser()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isJoined {
                    buzzerView
                } else {
                    joinView
                }
            }
            .navigationTitle("Player")
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
        }
        .onDisappear {
            nearbyBrowser.stop()
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
        VStack(spacing: 20) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 64))
                .foregroundStyle(JeffpardyTheme.gold)

            Text("Join a Game")
                .font(.largeTitle.bold())

            VStack(spacing: 12) {
                if !nearbyBrowser.games.isEmpty {
                    nearbyGames
                }

                CodeField(title: "6-character game code", text: $viewModel.gameCode)

                TextField("Team name", text: $viewModel.team)
                    .textInputAutocapitalization(.words)
                    .textFieldStyle(.roundedBorder)

                TextField("Player name", text: $viewModel.name)
                    .textInputAutocapitalization(.words)
                    .textFieldStyle(.roundedBorder)
            }
            .frame(maxWidth: 420)

            Button {
                Task {
                    await viewModel.join()
                }
            } label: {
                if viewModel.connectionState == .connecting {
                    ProgressView()
                        .tint(.black)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Join Game")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(JeffpardyTheme.gold)
            .foregroundStyle(.black)
            .frame(maxWidth: 420)
            .disabled(!viewModel.canJoin)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .jeffpardyBackground()
    }

    private var nearbyGames: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nearby Games")
                .font(.headline)

            ForEach(nearbyBrowser.games) { game in
                Button {
                    viewModel.gameCode = game.gameCode
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
                    .background(.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var buzzerView: some View {
        VStack(spacing: 24) {
            HStack {
                Label(viewModel.connectionState.label, systemImage: connectionIcon)
                Spacer()
                Text(viewModel.gameCode.uppercased())
                    .font(.headline.monospaced())
            }
            .foregroundStyle(.white.opacity(0.75))

            Spacer()

            Text("\(viewModel.name) • \(viewModel.team)")
                .font(.title2.bold())

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
                .background(buzzerColor)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.75), lineWidth: 8)
                }
                .shadow(color: buzzerColor.opacity(0.65), radius: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Jeffpardy buzzer")
            .accessibilityHint("Tap when the buzzer turns green")

            Text(buzzerHelp)
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
    PlayerView()
}
