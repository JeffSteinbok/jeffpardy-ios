import SwiftUI

struct HostSecondaryView: View {
    @State private var displayURL: URL?
    @State private var errorMessage: String?
    @StateObject private var nearbyAdvertiser = NearbyGameAdvertiser()

    var body: some View {
        NavigationStack {
            Group {
                if let displayURL {
                    WebView(url: displayURL)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    scannerView
                }
            }
            .navigationTitle("HOST DISPLAY")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(JeffpardyTheme.chrome, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert(
                "Invalid QR Code",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .toolbar {
                if displayURL != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Scan Another") {
                            nearbyAdvertiser.stop()
                            displayURL = nil
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
                            .multilineTextAlignment(.center)
                        Text("Open Jeffpardy on a device with a camera to scan the host QR code.")
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
            errorMessage = "Scan a Jeffpardy Host Secondary QR code."
            return
        }

        let gameCode = String(fragment.prefix(6)).uppercased()
        displayURL = url
        nearbyAdvertiser.start(gameCode: gameCode)
    }
}

#Preview {
    HostSecondaryView()
}
