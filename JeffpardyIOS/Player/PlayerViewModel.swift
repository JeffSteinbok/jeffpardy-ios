import Foundation
import SignalRClient

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published var gameCode = ""
    @Published var team = ""
    @Published var name = ""
    @Published private(set) var connectionState = PlayerConnectionState.disconnected
    @Published private(set) var buzzerState = BuzzerState.inactive
    @Published private(set) var isJoined = false
    @Published private(set) var teams: [String: Team] = [:]
    @Published private(set) var scores: [String: Int] = [:]
    @Published private(set) var isGameOver = false
    @Published var handicap = 0
    @Published private(set) var finalPhase = FinalJeffpardyPhase.inactive
    @Published private(set) var finalMaxWager = 0
    @Published var finalWagerText = ""
    @Published private(set) var finalWager: Int?
    @Published var finalResponse = ""
    @Published private(set) var isFinalResponseSubmitted = false
    @Published private(set) var winnerFeedbackToken = 0
    @Published var errorMessage: String?

    private let hubURL: URL
    private let identityStore: PlayerIdentityStore
    private var connection: HubConnection?
    private var buzzerActivatedAt: ContinuousClock.Instant?
    private var earlyBuzzUnlockTask: Task<Void, Never>?
    private var finalClueShownAt: ContinuousClock.Instant?

    init(
        hubURL: URL = AppConfiguration.hubURL,
        identityStore: PlayerIdentityStore = PlayerIdentityStore()
    ) {
        self.hubURL = hubURL
        self.identityStore = identityStore
        name = identityStore.lastPlayerName
        team = identityStore.lastTeamName
    }

    var canJoin: Bool {
        gameCode.count == 6
            && !team.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && connectionState == .connected
    }

    var sortedTeams: [Team] {
        teams.values.sorted {
            let leftScore = scores[$0.name] ?? 0
            let rightScore = scores[$1.name] ?? 0
            if leftScore != rightScore {
                return leftScore > rightScore
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    func connectToLobby(gameCode: String) async {
        let normalizedCode = gameCode.uppercased()
        guard normalizedCode.count == 6 else {
            errorMessage = "Enter a 6-character game code."
            return
        }

        await disconnect()
        self.gameCode = normalizedCode
        connectionState = .connecting
        errorMessage = nil

        let newConnection = makeConnection()
        connection = newConnection
        await registerHandlers(on: newConnection)

        do {
            try await newConnection.start()
            connectionState = .connected
            try await registerPlayerLobby(on: newConnection)
        } catch {
            connectionState = .disconnected
            errorMessage = "Unable to find that game: \(error.localizedDescription)"
            connection = nil
        }
    }

    func join() async {
        guard canJoin else {
            errorMessage = "Enter a 6-character game code, team, and player name."
            return
        }

        errorMessage = nil

        do {
            let activeConnection: HubConnection
            if let connection, connectionState == .connected {
                activeConnection = connection
            } else {
                await connectToLobby(gameCode: gameCode)
                guard let connection, connectionState == .connected else {
                    return
                }
                activeConnection = connection
            }

            try await registerPlayer(on: activeConnection)
            identityStore.savePlayer(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                team: team.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            isJoined = true
        } catch {
            errorMessage = "Unable to join the game: \(error.localizedDescription)"
        }
    }

    func resumeConnection() async {
        guard !gameCode.isEmpty else {
            return
        }

        let wasJoined = isJoined
        if let connection {
            await connection.stop()
        }

        connectionState = .reconnecting
        errorMessage = nil
        let newConnection = makeConnection()
        connection = newConnection
        await registerHandlers(on: newConnection)

        do {
            try await newConnection.start()
            if wasJoined {
                try await registerPlayer(on: newConnection)
            } else {
                try await registerPlayerLobby(on: newConnection)
            }
            connectionState = .connected
        } catch {
            connectionState = .disconnected
            errorMessage = wasJoined
                ? "Unable to reconnect to the game: \(error.localizedDescription)"
                : "Unable to reconnect to the lobby: \(error.localizedDescription)"
        }
    }

    func buzz() async {
        guard isJoined else {
            return
        }

        guard case .ready = buzzerState, let buzzerActivatedAt else {
            applyEarlyBuzzLockout()
            return
        }

        let duration = buzzerActivatedAt.duration(to: .now)
        let reactionTime = max(0, Int(duration.components.seconds * 1_000)
            + Int(duration.components.attoseconds / 1_000_000_000_000_000))
        buzzerState = .submitted(reactionTime: reactionTime)

        do {
            try await connection?.send(
                method: "buzzIn",
                arguments: gameCode,
                reactionTime,
                handicap,
                identityStore.playerID(for: gameCode)
            )
        } catch {
            buzzerState = .ready
            errorMessage = "The buzz could not be sent: \(error.localizedDescription)"
        }
    }

    func disconnect() async {
        earlyBuzzUnlockTask?.cancel()
        earlyBuzzUnlockTask = nil
        if let connection {
            await connection.stop()
        }
        connection = nil
        isJoined = false
        connectionState = .disconnected
        buzzerState = .inactive
        buzzerActivatedAt = nil
        teams = [:]
        scores = [:]
        isGameOver = false
        finalPhase = .inactive
        finalMaxWager = 0
        finalWagerText = ""
        finalWager = nil
        finalResponse = ""
        isFinalResponseSubmitted = false
        finalClueShownAt = nil
    }

    private func registerHandlers(on connection: HubConnection) async {
        await connection.on("updateUsers") { [weak self] (teams: [String: Team]) in
            await MainActor.run {
                self?.teams = teams
            }
        }

        await connection.on("broadcastScores") { [weak self] (scores: [String: Int]) in
            await MainActor.run {
                self?.scores = scores
            }
        }

        await connection.on("endGame") { [weak self] (scores: [String: Int]) in
            await MainActor.run {
                self?.scores = scores
                self?.isGameOver = true
                self?.finalPhase = .inactive
            }
        }

        await connection.on("activateBuzzer") { [weak self] in
            await MainActor.run {
                self?.buzzerActivatedAt = .now
                self?.buzzerState = .ready
            }
        }

        await connection.on("resetBuzzer") { [weak self] in
            await MainActor.run {
                self?.buzzerActivatedAt = nil
                self?.buzzerState = .inactive
            }
        }

        await connection.on("assignWinner") {
            [weak self] (player: Player, reactionTime: Int, _: [BuzzerAttempt]) in
            await MainActor.run {
                guard let self else {
                    return
                }
                self.buzzerState = .winner(
                    name: player.name,
                    team: player.team,
                    reactionTime: reactionTime
                )
                if player.name == self.name && player.team == self.team {
                    self.winnerFeedbackToken += 1
                }
            }
        }

        await connection.on("startFinalJeffpardy") { [weak self] (scores: [String: Int]) in
            await MainActor.run {
                guard let self, !self.team.isEmpty else {
                    return
                }

                let isNewFinal = self.finalPhase == .inactive
                self.scores = scores
                self.finalMaxWager = max(scores[self.team] ?? 0, 0)
                self.finalPhase = .wager
                if isNewFinal {
                    self.finalWager = nil
                    self.finalWagerText = self.finalMaxWager == 0 ? "0" : ""
                    self.finalResponse = ""
                    self.isFinalResponseSubmitted = false
                    self.finalClueShownAt = nil
                }

                if self.finalMaxWager == 0 && self.finalWager == nil {
                    Task {
                        await self.submitFinalWager()
                    }
                }
            }
        }

        await connection.on("showFinalJeffpardyClue") { [weak self] in
            await MainActor.run {
                self?.finalClueShownAt = .now
                self?.finalPhase = .response
            }
        }

        await connection.on("endFinalJeffpardy") { [weak self] in
            await MainActor.run {
                self?.finalPhase = .ended
            }
        }

        await connection.onReconnecting { [weak self] _ in
            await MainActor.run {
                self?.connectionState = .reconnecting
            }
        }

        await connection.onReconnected { [weak self] in
            guard let self else {
                return
            }

            do {
                if self.isJoined {
                    try await self.registerPlayer(on: connection)
                } else {
                    try await self.registerPlayerLobby(on: connection)
                }
                await MainActor.run {
                    self.connectionState = .connected
                }
            } catch {
                await MainActor.run {
                    self.connectionState = .disconnected
                    self.errorMessage = "Reconnected, but could not rejoin the game."
                }
            }
        }

        await connection.onClosed { [weak self] error in
            await MainActor.run {
                self?.connectionState = .disconnected
                if let error {
                    self?.errorMessage = "Connection closed: \(error.localizedDescription)"
                }
            }
        }
    }

    func submitFinalWager() async {
        guard finalPhase == .wager, finalWager == nil else {
            return
        }
        guard
            let wager = Int(finalWagerText),
            (0...finalMaxWager).contains(wager)
        else {
            errorMessage = "Enter a wager between 0 and \(finalMaxWager)."
            return
        }

        do {
            try await connection?.send(
                method: "submitWager",
                arguments: gameCode,
                wager,
                identityStore.playerID(for: gameCode)
            )
            finalWager = wager
        } catch {
            errorMessage = "The wager could not be submitted: \(error.localizedDescription)"
        }
    }

    func submitFinalResponse() async {
        guard finalPhase == .response, !isFinalResponseSubmitted else {
            return
        }
        guard let finalClueShownAt else {
            errorMessage = "Wait for the Final Jeffpardy clue before responding."
            return
        }

        let trimmedResponse = finalResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedResponse.isEmpty else {
            errorMessage = "Enter your Final Jeffpardy response."
            return
        }

        let duration = finalClueShownAt.duration(to: .now)
        let responseTime = max(0, Int(duration.components.seconds * 1_000)
            + Int(duration.components.attoseconds / 1_000_000_000_000_000))

        do {
            try await connection?.send(
                method: "submitAnswer",
                arguments: gameCode,
                trimmedResponse,
                responseTime,
                identityStore.playerID(for: gameCode)
            )
            isFinalResponseSubmitted = true
        } catch {
            errorMessage = "The response could not be submitted: \(error.localizedDescription)"
        }
    }

    private func makeConnection() -> HubConnection {
        HubConnectionBuilder()
            .withUrl(url: hubURL.absoluteString)
            .withAutomaticReconnect()
            .build()
    }

    private func registerPlayerLobby(on connection: HubConnection) async throws {
        try await connection.send(
            method: "connectPlayerLobby",
            arguments: gameCode.uppercased()
        )
    }

    private func registerPlayer(on connection: HubConnection) async throws {
        try await connection.send(
            method: "connectPlayer",
            arguments: gameCode.uppercased(),
            team.trimmingCharacters(in: .whitespacesAndNewlines),
            name.trimmingCharacters(in: .whitespacesAndNewlines),
            identityStore.playerID(for: gameCode)
        )
    }

    private func applyEarlyBuzzLockout() {
        guard buzzerState == .inactive else {
            return
        }

        buzzerState = .locked
        earlyBuzzUnlockTask?.cancel()
        earlyBuzzUnlockTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else {
                return
            }
            self?.buzzerState = .inactive
        }
    }
}
