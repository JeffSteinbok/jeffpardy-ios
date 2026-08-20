import Foundation
import SignalRClient

@MainActor
final class HostSecondaryViewModel: ObservableObject {
    @Published private(set) var connectionState = PlayerConnectionState.disconnected
    @Published private(set) var displayState = HostDisplayState.waiting
    @Published private(set) var topBuzzers: [BuzzerAttempt] = []
    @Published private(set) var teams: [String: Team] = [:]
    @Published var errorMessage: String?

    private let hubURL: URL
    private var connection: HubConnection?
    private var gameCode = ""
    private var hostCode = ""

    init(hubURL: URL = AppConfiguration.hubURL) {
        self.hubURL = hubURL
    }

    var isConnected: Bool {
        connectionState == .connected
    }

    func connect(gameCode: String, hostCode: String) async {
        await disconnect()
        self.gameCode = gameCode.uppercased()
        self.hostCode = hostCode.uppercased()
        connectionState = .connecting
        errorMessage = nil

        let newConnection = HubConnectionBuilder()
            .withUrl(url: hubURL.absoluteString)
            .withAutomaticReconnect()
            .build()
        connection = newConnection
        await registerHandlers(on: newConnection)

        do {
            try await newConnection.start()
            try await registerHost(on: newConnection)
            connectionState = .connected
        } catch {
            connectionState = .disconnected
            errorMessage = "Unable to connect the host display: \(error.localizedDescription)"
            connection = nil
        }
    }

    func disconnect() async {
        if let connection {
            await connection.stop()
        }
        connection = nil
        connectionState = .disconnected
        displayState = .waiting
        topBuzzers = []
        teams = [:]
    }

    private func registerHandlers(on connection: HubConnection) async {
        await connection.on("updateUsers") { [weak self] (teams: [String: Team]) in
            await MainActor.run {
                self?.teams = teams
            }
        }

        await connection.on("startRound") { [weak self] (round: HostGameRound) in
            await MainActor.run {
                self?.displayState = .round(round)
                self?.topBuzzers = []
            }
        }

        await connection.on("showClue") { [weak self] (clue: HostClue) in
            await MainActor.run {
                self?.displayState = .clue(clue)
                self?.topBuzzers = []
            }
        }

        await connection.on("assignWinner") {
            [weak self] (_: Player, _: Int, topBuzzers: [BuzzerAttempt]) in
            await MainActor.run {
                self?.topBuzzers = topBuzzers
            }
        }

        await connection.on("resetBuzzer") { [weak self] in
            await MainActor.run {
                self?.topBuzzers = []
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
                try await self.registerHost(on: connection)
                await MainActor.run {
                    self.connectionState = .connected
                }
            } catch {
                await MainActor.run {
                    self.connectionState = .disconnected
                    self.errorMessage = "Reconnected, but could not restore the host display."
                }
            }
        }

        await connection.onClosed { [weak self] error in
            await MainActor.run {
                self?.connectionState = .disconnected
                if let error {
                    self?.errorMessage = "Host connection closed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func registerHost(on connection: HubConnection) async throws {
        try await connection.send(
            method: "connectHost",
            arguments: gameCode,
            hostCode
        )
    }
}

