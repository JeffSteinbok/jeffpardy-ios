import Foundation

struct PlayerIdentityStore {
    private enum Key {
        static let playerName = "jeffpardy.lastPlayerName"
        static let teamName = "jeffpardy.lastTeamName"
    }

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

    var lastPlayerName: String {
        defaults.string(forKey: Key.playerName) ?? ""
    }

    var lastTeamName: String {
        defaults.string(forKey: Key.teamName) ?? ""
    }

    func savePlayer(name: String, team: String) {
        defaults.set(name, forKey: Key.playerName)
        defaults.set(team, forKey: Key.teamName)
    }
}
