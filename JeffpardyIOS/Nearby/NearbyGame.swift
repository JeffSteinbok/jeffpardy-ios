import Foundation
import MultipeerConnectivity

struct NearbyGame: Identifiable, Equatable {
    let peerID: MCPeerID
    let gameCode: String
    let hostName: String

    var id: String {
        peerID.displayName
    }

    static func == (lhs: NearbyGame, rhs: NearbyGame) -> Bool {
        lhs.peerID == rhs.peerID
            && lhs.gameCode == rhs.gameCode
            && lhs.hostName == rhs.hostName
    }
}

enum NearbyGameService {
    static let type = "jeffpardy"
    static let gameCodeKey = "gameCode"
}

