import Combine
import Foundation
import Network

@MainActor
final class TVSessionModel: ObservableObject {
    @Published private(set) var phase: ConnectionPhase = .idle
    @Published private(set) var presentation = PresentationState()
    @Published private(set) var revision = 0
    @Published private(set) var events: [ConnectionEvent] = []

    private var peer: PeerConnection?
    private var sessionID = UUID()
    private var processedMessageIDs: Set<UUID> = []
    private var processedMessageOrder: [UUID] = []

    func connect(to endpoint: NWEndpoint) {
        let oldPeer = peer
        peer = nil
        oldPeer?.cancel()

        sessionID = UUID()
        revision = 0
        processedMessageIDs.removeAll(keepingCapacity: true)
        processedMessageOrder.removeAll(keepingCapacity: true)

        let connection = NWConnection(to: endpoint, using: .applicationService)
        let peer = PeerConnection(connection: connection)
        peer.onMessage = { [weak self] connectionID, message in
            Task { @MainActor in self?.handle(message, connectionID: connectionID) }
        }
        peer.onStateChange = { [weak self] connectionID, state in
            Task { @MainActor in self?.handleConnectionState(state, connectionID: connectionID) }
        }

        self.peer = peer
        phase = .connecting
        record("Connecting to the selected iPad")
        peer.start()
    }

    func disconnect() {
        let oldPeer = peer
        peer = nil
        oldPeer?.cancel()
        phase = .idle
        record("Disconnected companion session")
    }

    private func handle(_ envelope: CompanionEnvelope, connectionID: UUID) {
        guard peer?.identifier == connectionID else {
            record("Ignored a message from a replaced connection")
            return
        }
        guard envelope.protocolVersion == CompanionProtocolVersion.current else {
            send(.protocolError("Unsupported protocol version \(envelope.protocolVersion)."))
            failSession("The iPad uses an incompatible protocol version")
            return
        }
        guard envelope.sessionID == sessionID else {
            record("Ignored a message for another session")
            return
        }
        guard remember(envelope.messageID) else {
            record("Ignored duplicate message \(envelope.messageID.uuidString.prefix(8))")
            publishSnapshot()
            return
        }

        switch envelope.payload {
        case .hello(let hello):
            guard hello.role == .companion else {
                failSession("Expected the companion peer role")
                return
            }
            guard hello.contentVersion == CompanionProtocolVersion.content else {
                send(.protocolError("Incompatible content version \(hello.contentVersion)."))
                failSession("The iPad content version is incompatible")
                return
            }
            record("Negotiated with iPad app \(hello.appVersion)")

        case .command(let request):
            guard request.lastKnownRevision <= revision else {
                send(.protocolError("The command references a future state revision."))
                publishSnapshot()
                return
            }

            switch PresentationReducer.apply(request.command, to: &presentation) {
            case .changed:
                revision += 1
                record("Applied command; state is now revision \(revision)")
            case .unchanged:
                record("Command required no state change")
            case .rejected(let reason):
                send(.protocolError(reason))
                record("Rejected command: \(reason)")
            }
            publishSnapshot()

        case .protocolError(let message):
            record("iPad reported a protocol error: \(message)")

        case .snapshot:
            record("Ignored an unexpected snapshot from iPad")
        }
    }

    private func publishHello() {
        let hello = PeerHello(
            role: .television,
            contentVersion: CompanionProtocolVersion.content,
            appVersion: CompanionAppMetadata.version
        )
        send(.hello(hello))
    }

    private func publishSnapshot() {
        send(.snapshot(StateSnapshot(revision: revision, state: presentation)))
    }

    private func send(_ payload: CompanionPayload) {
        peer?.send(CompanionEnvelope(sessionID: sessionID, payload: payload))
    }

    private func failSession(_ message: String) {
        let oldPeer = peer
        peer = nil
        oldPeer?.cancel()
        phase = .failed(message)
        record("Session failed: \(message)")
    }

    private func remember(_ messageID: UUID) -> Bool {
        guard processedMessageIDs.insert(messageID).inserted else { return false }
        processedMessageOrder.append(messageID)

        if processedMessageOrder.count > 128 {
            let expired = processedMessageOrder.removeFirst()
            processedMessageIDs.remove(expired)
        }
        return true
    }

    private func handleConnectionState(_ state: NWConnection.State, connectionID: UUID) {
        guard peer?.identifier == connectionID else { return }

        switch state {
        case .ready:
            phase = .connected
            record("Encrypted local connection is ready")
            publishHello()
            publishSnapshot()

        case .waiting(let error):
            phase = .connecting
            record("Connection is waiting: \(error.localizedDescription)")

        case .failed(let error):
            peer = nil
            phase = .failed(error.localizedDescription)
            record("Connection failed: \(error.localizedDescription)")

        case .cancelled:
            peer = nil
            phase = .idle
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
