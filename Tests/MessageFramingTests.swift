import Foundation
import XCTest

final class MessageFramingTests: XCTestCase {
    func testRoundTripEnvelope() throws {
        let envelope = makeEnvelope(.command(CommandRequest(command: .nextCard, lastKnownRevision: 3)))
        let data = try MessageFramer.frame(envelope)
        var framer = MessageFramer()

        XCTAssertEqual(try framer.append(data), [envelope])
        XCTAssertTrue(framer.buffer.isEmpty)
    }

    func testFragmentedFrameIsBufferedUntilComplete() throws {
        let envelope = makeEnvelope(.snapshot(StateSnapshot(revision: 4, state: PresentationState())))
        let data = try MessageFramer.frame(envelope)
        var framer = MessageFramer()

        for byte in data.dropLast() {
            XCTAssertTrue(try framer.append(Data([byte])).isEmpty)
        }

        XCTAssertEqual(try framer.append(Data([data.last!])), [envelope])
        XCTAssertTrue(framer.buffer.isEmpty)
    }

    func testCoalescedFramesAreDecodedInOrder() throws {
        let first = makeEnvelope(.command(CommandRequest(command: .previousCard, lastKnownRevision: 2)))
        let second = makeEnvelope(.command(CommandRequest(command: .addReaction, lastKnownRevision: 2)))
        var data = try MessageFramer.frame(first)
        data.append(try MessageFramer.frame(second))
        var framer = MessageFramer()

        XCTAssertEqual(try framer.append(data), [first, second])
    }

    func testZeroLengthFrameIsRejected() {
        var framer = MessageFramer()

        XCTAssertThrowsError(try framer.append(Data([0, 0, 0, 0]))) { error in
            XCTAssertEqual(error as? MessageFramingError, .invalidFrameLength)
        }
    }

    func testOversizedFrameIsRejectedBeforePayloadArrives() {
        let oversizedLength = UInt32(MessageFramer.maximumPayloadSize + 1)
        let header = Data([
            UInt8((oversizedLength >> 24) & 0xff),
            UInt8((oversizedLength >> 16) & 0xff),
            UInt8((oversizedLength >> 8) & 0xff),
            UInt8(oversizedLength & 0xff)
        ])
        var framer = MessageFramer()

        XCTAssertThrowsError(try framer.append(header)) { error in
            XCTAssertEqual(
                error as? MessageFramingError,
                .frameTooLarge(MessageFramer.maximumPayloadSize + 1)
            )
        }
    }

    private func makeEnvelope(_ payload: CompanionPayload) -> CompanionEnvelope {
        CompanionEnvelope(
            sessionID: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            payload: payload,
            messageID: UUID()
        )
    }
}
