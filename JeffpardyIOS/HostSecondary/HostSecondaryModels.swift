import Foundation

struct HostCategory: Codable, Equatable {
    let title: String
    let comment: String?
    let airDate: String?

    var formattedAirDate: String? {
        guard let airDate else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let serverFormatter = DateFormatter()
        serverFormatter.locale = Locale(identifier: "en_US_POSIX")
        serverFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        serverFormatter.dateFormat = airDate.contains("T")
            ? "yyyy-MM-dd'T'HH:mm:ss"
            : "yyyy-MM-dd"
        let date = formatter.date(from: airDate)
            ?? ISO8601DateFormatter().date(from: airDate)
            ?? serverFormatter.date(from: airDate)
        guard let date else {
            return nil
        }

        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "en_US_POSIX")
        outputFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        outputFormatter.dateFormat = "M/d/yyyy"
        return outputFormatter.string(from: date)
    }
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
