import XCTest
@testable import JeffpardyIOS

final class SignalRModelDecodingTests: XCTestCase {
    func testTeamDictionaryDecodesServerPlayerPayload() throws {
        let data = Data(
            """
            {
              "Blue": {
                "name": "Blue",
                "players": [
                  {
                    "team": "Blue",
                    "name": "Jeff",
                    "connectionId": "connection-1",
                    "playerId": "player-1"
                  }
                ]
              }
            }
            """.utf8
        )

        let teams = try JSONDecoder().decode([String: Team].self, from: data)

        XCTAssertEqual(teams["Blue"]?.players.first?.name, "Jeff")
    }

    func testHostRoundDecodesServerPayloadWithAdditionalCategoryFields() throws {
        let data = Data(
            """
            {
              "id": 0,
              "categories": [
                {
                  "title": "SCIENCE",
                  "comment": "Experiments",
                  "airDate": "2026-08-20T00:00:00Z",
                  "clues": []
                }
              ]
            }
            """.utf8
        )

        let round = try JSONDecoder().decode(HostGameRound.self, from: data)

        XCTAssertEqual(round.name, "Jeffpardy")
        XCTAssertEqual(round.categories.first?.title, "SCIENCE")
    }

    func testHostClueDecodesServerPayload() throws {
        let data = Data(
            """
            {
              "clue": "This planet is known as the red planet.",
              "question": "What is Mars?"
            }
            """.utf8
        )

        let clue = try JSONDecoder().decode(HostClue.self, from: data)

        XCTAssertEqual(clue.question, "What is Mars?")
    }
}

