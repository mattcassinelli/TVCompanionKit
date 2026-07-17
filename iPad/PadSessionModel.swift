import Combine
import Foundation
import Network

@MainActor
final class PadSessionModel: ObservableObject {
    @Published private(set) var phase: ConnectionPhase = .idle
    @Published private(set) var presentation = PresentationState()
    @Published private(set) var revision = 0
    @Published private(set) var events: [ConnectionEvent] = []

    private let listenerQueue = DispatchQueue(label: "TVCompanionKit.Listener")
    private var listener: NWListener?
    private var listenerID: UUID?
    private var peer: PeerConnection?
    private var sessionID: UUID?

    func startListening() {
        guard listener == nil else { return }

        do {
            let listener = try NWListener(
                applicationService: CompanionService.identifier,
                using: .applicationService
            )
            let listenerID = UUID()

            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in self?.handleListenerState(state, listenerID: listenerID) }
            }
            listener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in self?.accept(connection, listenerID: listenerID) }
            }

            self.listener = listener
            self.listenerID = listenerID
            phase = .waiting
            record("Starting local application service")
            listener.start(queue: listenerQueue)
        } catch {
            phase = .failed(error.localizedDescription)
            record("Listener creation failed: \(error.localizedDescription)")
        }
    }

    func ensureListening() {
        if listener == nil {
            startListening()
        }
    }

    func retry() {
        if listener == nil {
            startListening()
        } else if peer == nil {
            phase = .waiting
            record("Ready for another connection")
        }
    }

    func send(_ command: CompanionCommand) {
        guard phase == .connected, let sessionID else {
            record("Ignored command while no negotiated session is active")
            return
        }

        let request = CommandRequest(command: command, lastKnownRevision: revision)
        peer?.send(CompanionEnvelope(sessionID: sessionID, payload: .command(request)))
        record("Sent \(command.logName) at revision \(revision)")
    }

    func disconnect() {
        let oldPeer = peer
        peer = nil
        sessionID = nil
        revision = 0
        oldPeer?.cancel()
        phase = listener == nil ? .idle : .waiting
        record("Disconnected companion session")
    }

    private func accept(_ connection: NWConnection, listenerID: UUID) {
        guard self.listenerID == listenerID else {
            connection.cancel()
            return
        }

        let oldPeer = peer
        peer = nil
        oldPeer?.cancel()

        let peer = PeerConnection(connection: connection)
        peer.onMessage = { [weak self] connectionID, message in
            Task { @MainActor in self?.handle(message, connectionID: connectionID) }
        }
        peer.onStateChange = { [weak self] connectionID, state in
            Task { @MainActor in self?.handleConnectionState(state, connectionID: connectionID) }
        }

        self.peer = peer
        sessionID = nil
        revision = 0
        phase = .connecting
        record("Apple TV requested a connection")
        peer.start()
    }

    private func handle(_ envelope: CompanionEnvelope, connectionID: UUID) {
        guard peer?.identifier == connectionID else {
            record("Ignored a message from a replaced connection")
            return
        }
        guard envelope.protocolVersion == CompanionProtocolVersion.current else {
            failHandshake("Protocol version \(envelope.protocolVersion) is unsupported")
            return
        }

        switch envelope.payload {
        case .hello(let hello):
            guard hello.role == .television else {
                failHandshake("Expected the television peer role")
                return
            }
            guard hello.contentVersion == CompanionProtocolVersion.content else {
                failHandshake("Content version \(hello.contentVersion) is incompatible")
                return
            }

            sessionID = envelope.sessionID
            revision = 0
            phase = .connected
            record("Negotiated protocol v\(envelope.protocolVersion) with TV app \(hello.appVersion)")
            sendHello()
            send(.requestSnapshot)

        case .snapshot(let snapshot):
            guard envelope.sessionID == sessionID else {
                record("Ignored a snapshot for another session")
                return
            }
            guard snapshot.state.isValid else {
                failHandshake("Received an invalid presentation snapshot")
                return
            }
            guard snapshot.revision >= revision else {
                record("Ignored stale snapshot revision \(snapshot.revision)")
                return
            }

            presentation = snapshot.state
            revision = snapshot.revision
            record("Applied snapshot revision \(revision)")

        case .protocolError(let message):
            record("TV rejected a message: \(message)")

        case .command:
            record("Ignored an unexpected command from Apple TV")
        }
    }

    private func sendHello() {
        guard let sessionID else { return }
        let hello = PeerHello(
            role: .companion,
            contentVersion: CompanionProtocolVersion.content,
            appVersion: CompanionAppMetadata.version
        )
        peer?.send(CompanionEnvelope(sessionID: sessionID, payload: .hello(hello)))
    }

    private func failHandshake(_ message: String) {
        let oldPeer = peer
        peer = nil
        sessionID = nil
        oldPeer?.cancel()
        phase = .failed(message)
        record("Handshake failed: \(message)")
    }

    private func handleListenerState(_ state: NWListener.State, listenerID: UUID) {
        guard self.listenerID == listenerID else { return }

        switch state {
        case .ready:
            if peer == nil { phase = .waiting }
            record("Local application service is ready")

        case .failed(let error):
            listener = nil
            self.listenerID = nil
            phase = .failed(error.localizedDescription)
            record("Listener failed: \(error.localizedDescription)")

        case .cancelled:
            listener = nil
            self.listenerID = nil
            if peer == nil { phase = .idle }
            record("Local application service stopped")

        default:
            break
        }
    }

    private func handleConnectionState(_ state: NWConnection.State, connectionID: UUID) {
        guard peer?.identifier == connectionID else { return }

        switch state {
        case .ready:
            phase = .negotiating
            record("Encrypted transport is ready; waiting for TV hello")

        case .waiting(let error):
            phase = .connecting
            record("Connection is waiting: \(error.localizedDescription)")

        case .failed(let error):
            peer = nil
            sessionID = nil
            phase = .failed(error.localizedDescription)
            record("Connection failed: \(error.localizedDescription)")

        case .cancelled:
            peer = nil
            sessionID = nil
            phase = listener == nil ? .idle : .waiting
            record("Connection closed")

        default:
            break
        }
    }

    private func record(_ message: String) {
        events.append(ConnectionEvent(message))
        if events.count > 50 {
            events.removeFirst(events.count - 50)
        }
    }
}

private extension CompanionCommand {
    var logName: String {
        switch self {
        case .previousCard: "previous card"
        case .nextCard: "next card"
        case .selectCard: "selected stage moment"
        case .addReaction: "reaction"
        case .setSpotlight: "spotlight"
        case .setSharedMessage: "shared message"
        case .requestSnapshot: "snapshot request"
        }
    }
}
