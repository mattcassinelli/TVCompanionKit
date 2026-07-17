import Foundation
import Network

final class PeerConnection {
    let identifier = UUID()

    var onMessage: ((UUID, CompanionEnvelope) -> Void)?
    var onStateChange: ((UUID, NWConnection.State) -> Void)?

    private let connection: NWConnection
    private let queue = DispatchQueue(label: "TVCompanionKit.PeerConnection")
    private var framer = MessageFramer()

    init(connection: NWConnection) {
        self.connection = connection
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            self.onStateChange?(self.identifier, state)
        }
        connection.start(queue: queue)
        receiveNextChunk()
    }

    func send(_ message: CompanionEnvelope) {
        do {
            let data = try MessageFramer.frame(message)
            connection.send(content: data, completion: .contentProcessed { [weak self] error in
                if let error {
                    guard let self else { return }
                    self.onStateChange?(self.identifier, .failed(error))
                }
            })
        } catch {
            onStateChange?(identifier, .failed(NWError.posix(.EMSGSIZE)))
        }
    }

    func cancel() {
        connection.cancel()
    }

    private func receiveNextChunk() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, isComplete, error in
            guard let self else { return }

            if let data, !data.isEmpty {
                do {
                    let messages = try self.framer.append(data)
                    messages.forEach { self.onMessage?(self.identifier, $0) }
                } catch {
                    self.connection.cancel()
                    self.onStateChange?(self.identifier, .failed(NWError.posix(.EBADMSG)))
                    return
                }
            }

            if let error {
                self.onStateChange?(self.identifier, .failed(error))
                return
            }

            if isComplete {
                self.connection.cancel()
            } else {
                self.receiveNextChunk()
            }
        }
    }
}
