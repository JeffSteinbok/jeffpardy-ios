import Foundation

struct Player: Codable, Equatable {
    let team: String
    let name: String
    let connectionId: String
}

struct Team: Codable, Equatable {
    let name: String
    let players: [Player]
}

struct BuzzerAttempt: Codable {
    let player: Player
    let time: Int
}

enum PlayerConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting

    var label: String {
        switch self {
        case .disconnected: "Disconnected"
        case .connecting: "Connecting"
        case .connected: "Connected"
        case .reconnecting: "Reconnecting"
        }
    }
}

enum BuzzerState: Equatable {
    case inactive
    case ready
    case submitted(reactionTime: Int)
    case locked
    case winner(name: String, team: String, reactionTime: Int)

    var label: String {
        switch self {
        case .inactive:
            "WAIT"
        case .ready:
            "BUZZ"
        case let .submitted(reactionTime):
            "\(reactionTime) ms"
        case .locked:
            "LOCKED"
        case let .winner(name, _, _):
            name
        }
    }
}
