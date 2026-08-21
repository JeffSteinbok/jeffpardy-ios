import SwiftUI

struct RootView: View {
    private enum AppDestination {
        case chooser
        case player
        case hostSetup
        case hostScanner
    }

    @State private var destination = AppDestination.chooser
    @State private var pendingGameCode: String?

    var body: some View {
        Group {
            switch destination {
            case .chooser:
                roleChooser
            case .player:
                PlayerView(
                    pendingGameCode: $pendingGameCode,
                    onExit: { destination = .chooser }
                )
            case .hostSetup:
                hostSetup
            case .hostScanner:
                HostSecondaryView(
                    onExit: { destination = .hostSetup }
                )
            }
        }
        .transition(.opacity)
        .onOpenURL { url in
            guard let gameCode = AppConfiguration.gameCode(fromPlayerURL: url) else {
                return
            }

            pendingGameCode = gameCode
            destination = .player
        }
    }

    private var roleChooser: some View {
        VStack(spacing: 34) {
            Spacer()

            JeffpardyLogo()
                .frame(maxWidth: 360)

            VStack(spacing: 10) {
                Text("WHAT WOULD YOU LIKE TO DO?")
                    .font(.title2.weight(.black))
                    .fontWidth(.condensed)
                    .tracking(1.4)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black, radius: 2, x: 2, y: 2)

                Text("Host a game on another screen, or join as a player.")
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        destination = .player
                    }
                } label: {
                    Label("Play a Game", systemImage: "hand.tap.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(JeffpardyPrimaryButtonStyle())

                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        destination = .hostSetup
                    }
                } label: {
                    Label("Host a Game", systemImage: "tv.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(JeffpardyPrimaryButtonStyle())
            }
            .frame(maxWidth: 440)

            Spacer()
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .jeffpardyBackground()
    }

    private var hostSetup: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    JeffpardyLogo()
                        .frame(maxWidth: 340)
                        .padding(.top, 36)

                    Text("HOST A GAME")
                        .font(.title.weight(.black))
                        .fontWidth(.condensed)
                        .tracking(2)
                        .shadow(color: .black, radius: 2, x: 2, y: 2)

                    JeffpardyCard {
                        VStack(alignment: .leading, spacing: 20) {
                            instruction(
                                number: 1,
                                title: "Start the game",
                                detail: "Open the Jeffpardy website on a computer or tablet and set up your game."
                            )

                            Link(destination: AppConfiguration.baseURL) {
                                Label(
                                    "Open jeffpardy.azurewebsites.net",
                                    systemImage: "safari"
                                )
                                .font(.headline.weight(.bold))
                                .foregroundStyle(JeffpardyTheme.gold)
                            }

                            Divider()
                                .overlay(.white.opacity(0.15))

                            instruction(
                                number: 2,
                                title: "Return to this app",
                                detail: "Once the game is ready, come back here and scan the private Host Secondary QR code."
                            )

                            Divider()
                                .overlay(.white.opacity(0.15))

                            instruction(
                                number: 3,
                                title: "Use this as the display",
                                detail: "Rounds, clues, responses, and buzzer results will appear here automatically."
                            )
                        }
                    }
                    .frame(maxWidth: 520)

                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            destination = .hostScanner
                        }
                    } label: {
                        Label("Scan Host Code", systemImage: "qrcode.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(JeffpardyPrimaryButtonStyle())
                    .frame(maxWidth: 520)
                    .disabled(!QRScannerView.isSupported)
                    .opacity(QRScannerView.isSupported ? 1 : 0.5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .jeffpardyBackground()
            .navigationTitle("")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        destination = .chooser
                    } label: {
                        Label("Home", systemImage: "chevron.left")
                    }
                }
            }
        }
    }

    private func instruction(
        number: Int,
        title: String,
        detail: String
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.headline.weight(.black))
                .foregroundStyle(JeffpardyTheme.boardDark)
                .frame(width: 34, height: 34)
                .background(JeffpardyTheme.gold)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(title.uppercased())
                    .font(.headline.weight(.black))
                    .tracking(0.8)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
    }
}

#Preview {
    RootView()
}
