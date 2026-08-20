import MultipeerConnectivity
import UIKit

@MainActor
final class NearbyGameBrowser: NSObject, ObservableObject {
    @Published private(set) var games: [NearbyGame] = []

    private let peerID = MCPeerID(displayName: "\(UIDevice.current.name)-player")
    private var browser: MCNearbyServiceBrowser?

    func start() {
        guard browser == nil else {
            return
        }

        let browser = MCNearbyServiceBrowser(
            peer: peerID,
            serviceType: NearbyGameService.type
        )
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser
    }

    func stop() {
        browser?.stopBrowsingForPeers()
        browser = nil
        games = []
    }

    deinit {
        browser?.stopBrowsingForPeers()
    }
}

extension NearbyGameBrowser: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        guard
            let gameCode = info?[NearbyGameService.gameCodeKey],
            gameCode.count == 6
        else {
            return
        }

        let game = NearbyGame(
            peerID: peerID,
            gameCode: gameCode.uppercased(),
            hostName: peerID.displayName
        )

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            games.removeAll { $0.peerID == peerID }
            games.append(game)
            games.sort { $0.hostName.localizedCaseInsensitiveCompare($1.hostName) == .orderedAscending }
        }
    }

    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {
        Task { @MainActor [weak self] in
            self?.games.removeAll { $0.peerID == peerID }
        }
    }

    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: Error
    ) {
        assertionFailure("Nearby game browsing failed: \(error.localizedDescription)")
    }
}

