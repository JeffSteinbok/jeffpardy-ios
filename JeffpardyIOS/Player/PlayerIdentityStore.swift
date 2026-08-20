import Foundation

struct PlayerIdentityStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func playerID(for gameCode: String) -> String {
        let key = "jeffpardy.playerId.\(gameCode.uppercased())"
        if let existingID = defaults.string(forKey: key) {
            return existingID
        }

        let playerID = UUID().uuidString
        defaults.set(playerID, forKey: key)
        return playerID
    }
}

