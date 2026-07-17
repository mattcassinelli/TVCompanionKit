import XCTest

final class PresentationReducerTests: XCTestCase {
    func testNextCardChangesState() {
        var state = PresentationState()

        XCTAssertEqual(PresentationReducer.apply(.nextCard, to: &state), .changed)
        XCTAssertEqual(state.selectedCard, 1)
        XCTAssertTrue(state.isValid)
    }

    func testCardBoundaryIsUnchanged() {
        var state = PresentationState(selectedCard: PresentationState.cards.count - 1)

        XCTAssertEqual(PresentationReducer.apply(.nextCard, to: &state), .unchanged)
        XCTAssertEqual(state.selectedCard, PresentationState.cards.count - 1)
    }

    func testSelectingAStageMomentChangesState() {
        var state = PresentationState()

        XCTAssertEqual(PresentationReducer.apply(.selectCard(2), to: &state), .changed)
        XCTAssertEqual(state.selectedCard, 2)
    }

    func testSelectingAnInvalidStageMomentIsRejected() {
        var state = PresentationState()

        guard case .rejected = PresentationReducer.apply(.selectCard(99), to: &state) else {
            return XCTFail("Expected an invalid selection to be rejected")
        }
        XCTAssertEqual(state.selectedCard, 0)
    }

    func testOversizedSharedMessageIsRejected() {
        var state = PresentationState()
        let original = state
        let oversizedMessage = String(
            repeating: "x",
            count: CompanionProtocolVersion.maximumSharedMessageLength + 1
        )

        guard case .rejected = PresentationReducer.apply(.setSharedMessage(oversizedMessage), to: &state) else {
            return XCTFail("Expected the message to be rejected")
        }
        XCTAssertEqual(state, original)
    }

    func testInvalidSnapshotStateIsDetectable() {
        let state = PresentationState(selectedCard: PresentationState.cards.count)

        XCTAssertFalse(state.isValid)
    }

    func testEnvelopeCarriesExplicitCompatibilityMetadata() {
        let envelope = CompanionEnvelope(
            sessionID: UUID(),
            payload: .hello(PeerHello(role: .television, contentVersion: CompanionProtocolVersion.content, appVersion: "1.0"))
        )

        XCTAssertEqual(envelope.protocolVersion, CompanionProtocolVersion.current)
        XCTAssertNotEqual(envelope.sessionID, UUID())
    }
}
