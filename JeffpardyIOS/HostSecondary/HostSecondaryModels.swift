import Foundation

struct HostCategory: Codable, Equatable {
    let title: String
    let comment: String?
}

struct HostGameRound: Codable, Equatable {
    let id: Int
    let categories: [HostCategory]

    var name: String {
        switch id {
        case 0:
            "Jeffpardy"
        case 1:
            "Super Jeffpardy"
        default:
            "Final Jeffpardy"
        }
    }
}

struct HostClue: Codable, Equatable {
    let clue: String
    let question: String
}

enum HostDisplayState: Equatable {
    case waiting
    case round(HostGameRound)
    case clue(HostClue)
}

