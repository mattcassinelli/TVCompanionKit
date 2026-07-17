import Foundation

enum MessageFramingError: Error, Equatable {
    case frameTooLarge(Int)
    case invalidFrameLength
}

struct MessageFramer {
    static let maximumPayloadSize = 1_048_576

    private(set) var buffer = Data()

    static func frame(_ message: CompanionEnvelope) throws -> Data {
        let payload = try JSONEncoder().encode(message)
        guard payload.count <= maximumPayloadSize else {
            throw MessageFramingError.frameTooLarge(payload.count)
        }

        var length = UInt32(payload.count).bigEndian
        var framed = withUnsafeBytes(of: &length) { Data($0) }
        framed.append(payload)
        return framed
    }

    mutating func append(_ data: Data) throws -> [CompanionEnvelope] {
        buffer.append(data)
        var messages: [CompanionEnvelope] = []

        while buffer.count >= MemoryLayout<UInt32>.size {
            let lengthData = buffer.prefix(MemoryLayout<UInt32>.size)
            let payloadLength = lengthData.reduce(UInt32.zero) { partial, byte in
                (partial << 8) | UInt32(byte)
            }

            guard payloadLength > 0 else {
                throw MessageFramingError.invalidFrameLength
            }
            guard payloadLength <= Self.maximumPayloadSize else {
                throw MessageFramingError.frameTooLarge(Int(payloadLength))
            }

            let fullFrameLength = MemoryLayout<UInt32>.size + Int(payloadLength)
            guard buffer.count >= fullFrameLength else { break }

            let payload = buffer.subdata(in: MemoryLayout<UInt32>.size..<fullFrameLength)
            messages.append(try JSONDecoder().decode(CompanionEnvelope.self, from: payload))
            buffer.removeSubrange(0..<fullFrameLength)
        }

        return messages
    }
}
