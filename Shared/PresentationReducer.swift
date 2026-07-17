import Foundation

enum PresentationReduction: Equatable {
    case changed
    case unchanged
    case rejected(String)
}

enum PresentationReducer {
    static func apply(_ command: CompanionCommand, to state: inout PresentationState) -> PresentationReduction {
        switch command {
        case .previousCard:
            guard state.selectedCard > PresentationState.cards.startIndex else { return .unchanged }
            state.selectedCard -= 1
            return .changed

        case .nextCard:
            guard state.selectedCard < PresentationState.cards.index(before: PresentationState.cards.endIndex) else {
                return .unchanged
            }
            state.selectedCard += 1
            return .changed

        case .selectCard(let index):
            guard PresentationState.cards.indices.contains(index) else {
                return .rejected("The selected stage moment does not exist.")
            }
            guard state.selectedCard != index else { return .unchanged }
            state.selectedCard = index
            return .changed

        case .addReaction:
            guard state.reactionCount < CompanionProtocolVersion.maximumReactionCount else {
                return .rejected("The reaction limit has been reached.")
            }
            state.reactionCount += 1
            return .changed

        case .setSpotlight(let isOn):
            guard state.isSpotlightOn != isOn else { return .unchanged }
            state.isSpotlightOn = isOn
            return .changed

        case .setSharedMessage(let message):
            guard message.count <= CompanionProtocolVersion.maximumSharedMessageLength else {
                return .rejected("Shared messages are limited to \(CompanionProtocolVersion.maximumSharedMessageLength) characters.")
            }
            guard state.sharedMessage != message else { return .unchanged }
            state.sharedMessage = message
            return .changed

        case .requestSnapshot:
            return .unchanged
        }
    }
}
