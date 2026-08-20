import MultipeerConnectivity
import UIKit

@MainActor
final class NearbyGameAdvertiser: NSObject, ObservableObject {
    private var advertiser: MCNearbyServiceAdvertiser?

    func start(gameCode: String) {
        stop()

        let normalizedCode = gameCode.uppercased()
        guard normalizedCode.count == 6 else {
            return
        }

        let peerID = MCPeerID(displayName: UIDevice.current.name)
        let advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: [NearbyGameService.gameCodeKey: normalizedCode],
            serviceType: NearbyGameService.type
        )
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
    }

    deinit {
        advertiser?.stopAdvertisingPeer()
    }
}

extension NearbyGameAdvertiser: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        invitationHandler(false, nil)
    }

    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: Error
    ) {
        assertionFailure("Nearby game advertising failed: \(error.localizedDescription)")
    }
}

