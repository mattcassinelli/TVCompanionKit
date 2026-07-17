import Foundation

enum CompanionService {
    static let identifier = "TVCompanionKit-Demo"
}

enum CompanionProtocolVersion {
    static let current = 1
    static let content = 2
    static let maximumSharedMessageLength = 500
    static let maximumReactionCount = 999_999
}

enum CompanionAppMetadata {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development"
    }
}

struct PresentationState: Codable, Equatable, Sendable {
    var selectedCard = 0
    var reactionCount = 0
    var isSpotlightOn = false
    var sharedMessage = ""

    var isValid: Bool {
        PresentationState.cards.indices.contains(selectedCard)
            && (0...CompanionProtocolVersion.maximumReactionCount).contains(reactionCount)
            && sharedMessage.count <= CompanionProtocolVersion.maximumSharedMessageLength
    }

    static let cards = [
        PresentationCard(
            eyebrow: "PAIR",
            title: "Bring the iPad into the room",
            subtitle: "Apple TV starts a secure, local companion session—without a code, account flow, or website.",
            takeaway: "The shared screen initiates; the personal device approves.",
            symbol: "ipad.and.iphone",
            colorName: "cyan"
        ),
        PresentationCard(
            eyebrow: "EXPLORE PRIVATELY",
            title: "Browse without interrupting the TV",
            subtitle: "The iPad can preview upcoming moments, show deeper context, and accept touch input while the TV stays focused.",
            takeaway: "Personal exploration should not disturb the shared experience.",
            symbol: "rectangle.stack.badge.play",
            colorName: "indigo"
        ),
        PresentationCard(
            eyebrow: "SEND WITH INTENT",
            title: "Put the right moment on the big screen",
            subtitle: "A deliberate action promotes a selection or message from the private console to the shared stage.",
            takeaway: "Nothing private appears on TV until the person chooses to share it.",
            symbol: "arrow.up.forward.app.fill",
            colorName: "orange"
        ),
        PresentationCard(
            eyebrow: "STAY IN SYNC",
            title: "Recover without losing the room",
            subtitle: "The TV remains authoritative while revisions, snapshots, and reconnect handling keep both interfaces coherent.",
            takeaway: "The TV experience remains useful even when the companion leaves.",
            symbol: "arrow.triangle.2.circlepath",
            colorName: "mint"
        )
    ]
}

struct PresentationCard: Codable, Equatable, Sendable {
    let eyebrow: String
    let title: String
    let subtitle: String
    let takeaway: String
    let symbol: String
    let colorName: String
}

enum CompanionCommand: Codable, Equatable, Sendable {
    case previousCard
    case nextCard
    case selectCard(Int)
    case addReaction
    case setSpotlight(Bool)
    case setSharedMessage(String)
    case requestSnapshot
}

enum PeerRole: String, Codable, Equatable, Sendable {
    case television
    case companion
}

struct PeerHello: Codable, Equatable, Sendable {
    let role: PeerRole
    let contentVersion: Int
    let appVersion: String
}

struct CommandRequest: Codable, Equatable, Sendable {
    let command: CompanionCommand
    let lastKnownRevision: Int
}

struct StateSnapshot: Codable, Equatable, Sendable {
    let revision: Int
    let state: PresentationState
}

enum CompanionPayload: Codable, Equatable, Sendable {
    case hello(PeerHello)
    case command(CommandRequest)
    case snapshot(StateSnapshot)
    case protocolError(String)
}

struct CompanionEnvelope: Codable, Equatable, Sendable {
    let protocolVersion: Int
    let sessionID: UUID
    let messageID: UUID
    let payload: CompanionPayload

    init(
        sessionID: UUID,
        payload: CompanionPayload,
        protocolVersion: Int = CompanionProtocolVersion.current,
        messageID: UUID = UUID()
    ) {
        self.protocolVersion = protocolVersion
        self.sessionID = sessionID
        self.messageID = messageID
        self.payload = payload
    }
}

enum ConnectionPhase: Equatable, Sendable {
    case idle
    case waiting
    case connecting
    case negotiating
    case connected
    case failed(String)

    var title: String {
        switch self {
        case .idle: "Not connected"
        case .waiting: "Ready for Apple TV"
        case .connecting: "Connecting…"
        case .negotiating: "Checking compatibility…"
        case .connected: "Connected"
        case .failed(let message): "Connection failed: \(message)"
        }
    }
}

struct ConnectionEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    let timestamp: Date
    let message: String

    init(_ message: String, id: UUID = UUID(), timestamp: Date = Date()) {
        self.id = id
        self.timestamp = timestamp
        self.message = message
    }
}
