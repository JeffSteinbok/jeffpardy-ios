import SwiftUI
import UIKit

struct HostSecondaryView: View {
    @State private var gameCode = ""
    @State private var localErrorMessage: String?
    @StateObject private var nearbyAdvertiser = NearbyGameAdvertiser()
    @StateObject private var viewModel = HostSecondaryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if gameCode.isEmpty {
                    scannerView
                } else {
                    nativeDisplay
                }
            }
            .navigationTitle("HOST DISPLAY")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(JeffpardyTheme.chrome, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert(
                "Jeffpardy",
                isPresented: Binding(
                    get: {
                        localErrorMessage != nil || viewModel.errorMessage != nil
                    },
                    set: {
                        if !$0 {
                            localErrorMessage = nil
                            viewModel.errorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    localErrorMessage = nil
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(localErrorMessage ?? viewModel.errorMessage ?? "")
            }
            .toolbar {
                if !gameCode.isEmpty {
                    if let playerURL = AppConfiguration.playerURL(gameCode: gameCode) {
                        ToolbarItem(placement: .topBarLeading) {
                            ShareLink(
                                item: playerURL,
                                subject: Text("Join my Jeffpardy game"),
                                message: Text("Join my Jeffpardy game \(gameCode).")
                            ) {
                                Label("Invite", systemImage: "square.and.arrow.up")
                            }
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Scan Another") {
                            resetDisplay()
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var scannerView: some View {
        if QRScannerView.isSupported {
            ZStack {
                QRScannerView { payload in
                    handleScannedPayload(payload)
                }
                .ignoresSafeArea(edges: .bottom)

                VStack {
                    JeffpardyLogo()
                        .frame(maxWidth: 300)
                        .padding(.top, 20)

                    Spacer()

                    JeffpardyCard {
                        HStack(spacing: 14) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(JeffpardyTheme.gold)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("SCAN HOST QR CODE")
                                    .font(.headline.weight(.black))
                                    .tracking(0.8)
                                Text("Point the camera at the secondary-window code.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                        }
                    }
                    .padding(24)
                }
            }
        } else {
            VStack(spacing: 28) {
                JeffpardyLogo()
                    .frame(maxWidth: 330)

                JeffpardyCard {
                    VStack(spacing: 14) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundStyle(JeffpardyTheme.gold)
                        Text("CAMERA SCANNING UNAVAILABLE")
                            .font(.headline.weight(.black))
                        Text("Use a device with a camera to scan the private host QR code.")
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .jeffpardyBackground()
        }
    }

    private var nativeDisplay: some View {
        VStack(spacing: 20) {
            HStack {
                Label(
                    viewModel.connectionState.label,
                    systemImage: connectionIcon
                )
                .font(.subheadline.weight(.bold))
                .foregroundStyle(
                    viewModel.isConnected
                        ? Color.green
                        : Color.white.opacity(0.65)
                )

                Spacer()

                Text(gameCode)
                    .font(.headline.monospaced().weight(.black))
                    .foregroundStyle(JeffpardyTheme.gold)
            }

            displayContent

            if !viewModel.topBuzzers.isEmpty {
                buzzerResults
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .jeffpardyBackground()
    }

    @ViewBuilder
    private var displayContent: some View {
        switch viewModel.displayState {
        case .waiting:
            VStack(spacing: 24) {
                Spacer()
                JeffpardyLogo()
                    .frame(maxWidth: 500)
                Text(
                    viewModel.isConnected
                        ? "Waiting for the host to start the round"
                        : "Connecting to the game"
                )
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.75))
                rosterSummary
                Spacer()
            }

        case let .round(round):
            ScrollView {
                VStack(spacing: 20) {
                    Text("\(round.name.uppercased()) ROUND")
                        .font(.system(size: 34, weight: .black))
                        .fontWidth(.condensed)
                        .tracking(1.4)
                        .shadow(color: .black, radius: 2, x: 2, y: 2)

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 220), spacing: 14)],
                        spacing: 14
                    ) {
                        ForEach(round.categories, id: \.title) { category in
                            JeffpardyCard {
                                VStack(spacing: 8) {
                                    Text(category.title.uppercased())
                                        .font(.title3.weight(.black))
                                        .multilineTextAlignment(.center)
                                    if let comment = category.comment, !comment.isEmpty {
                                        Text(comment)
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.65))
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 90)
                            }
                        }
                    }
                }
            }

        case let .clue(clue):
            VStack(spacing: 20) {
                Spacer()
                Text(htmlToPlainText(clue.clue))
                    .font(.system(size: 38, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.55)
                    .frame(maxWidth: 900)

                Divider()
                    .overlay(JeffpardyTheme.gold.opacity(0.5))

                Text(htmlToPlainText(clue.question))
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(JeffpardyTheme.gold)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: 900)
                Spacer()
            }
        }
    }

    private var rosterSummary: some View {
        JeffpardyCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("PLAYERS")
                    .font(.caption.weight(.black))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.6))

                if viewModel.teams.isEmpty {
                    Text("No players have joined yet.")
                        .foregroundStyle(.white.opacity(0.65))
                } else {
                    ForEach(
                        viewModel.teams.values.sorted { $0.name < $1.name },
                        id: \.name
                    ) { team in
                        Text(
                            "\(team.name): \(team.players.map(\.name).joined(separator: ", "))"
                        )
                        .font(.headline)
                    }
                }
            }
            .frame(maxWidth: 520, alignment: .leading)
        }
    }

    private var buzzerResults: some View {
        HStack(spacing: 12) {
            ForEach(Array(viewModel.topBuzzers.enumerated()), id: \.offset) {
                index,
                attempt in
                VStack(spacing: 4) {
                    Text(index == 0 ? "WINNER" : "#\(index + 1)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(JeffpardyTheme.gold)
                    Text(attempt.player.name)
                        .font(.headline.weight(.black))
                    Text("\(attempt.player.team) • \(attempt.time) ms")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(.black.opacity(index == 0 ? 0.45 : 0.25))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            index == 0
                                ? JeffpardyTheme.gold
                                : Color.white.opacity(0.15),
                            lineWidth: index == 0 ? 2 : 1
                        )
                }
            }
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

    private func handleScannedPayload(_ payload: String) {
        guard
            let url = URL(string: payload),
            ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
            url.host?.caseInsensitiveCompare(AppConfiguration.baseURL.host ?? "") == .orderedSame,
            url.path.lowercased() == "/hostsecondary",
            let fragment = url.fragment,
            fragment.count == 12,
            fragment.allSatisfy({ $0.isLetter || $0.isNumber })
        else {
            localErrorMessage = "Scan a Jeffpardy Host Secondary QR code."
            return
        }

        gameCode = String(fragment.prefix(6)).uppercased()
        let hostCode = String(fragment.suffix(6)).uppercased()
        nearbyAdvertiser.start(gameCode: gameCode)
        Task {
            await viewModel.connect(gameCode: gameCode, hostCode: hostCode)
        }
    }

    private func resetDisplay() {
        nearbyAdvertiser.stop()
        gameCode = ""
        Task {
            await viewModel.disconnect()
        }
    }

    private func htmlToPlainText(_ html: String) -> String {
        guard
            let data = html.data(using: .utf8),
            let attributed = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue,
                ],
                documentAttributes: nil
            )
        else {
            return html
        }

        return attributed.string
    }
}

#Preview {
    HostSecondaryView()
}
