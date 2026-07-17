import SwiftUI

struct PadContentView: View {
    @EnvironmentObject private var session: PadSessionModel
    @State private var draftMessage = ""
    @State private var lastSyncedMessage = ""

    private var isConnected: Bool { session.phase == .connected }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            ScrollView {
                VStack(spacing: 24) {
                    sessionHeader
                    stagePreview
                    controlDeck
                    momentQueue
                    privateComposer
                }
                .padding(32)
                .frame(maxWidth: 980)
                .frame(maxWidth: .infinity)
            }
            .background(Color.secondary.opacity(0.06))
            .navigationTitle("Session Console")
        }
        .onChange(of: session.presentation.sharedMessage, initial: true) { _, newValue in
            if draftMessage == lastSyncedMessage {
                draftMessage = newValue
            }
            lastSyncedMessage = newValue
        }
        .onChange(of: draftMessage) { _, newValue in
            if newValue.count > CompanionProtocolVersion.maximumSharedMessageLength {
                draftMessage = String(newValue.prefix(CompanionProtocolVersion.maximumSharedMessageLength))
            }
        }
    }

    private var sidebar: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TV COMPANION KIT")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text("Private controls for a shared screen")
                        .font(.title3.bold())
                }
                .padding(.vertical, 8)
            }

            Section("Connection") {
                Label(session.phase.title, systemImage: connectionSymbol)
                    .foregroundStyle(isConnected ? .green : .secondary)

                if isConnected {
                    LabeledContent("TV state", value: "r\(session.revision)")
                    Button("Disconnect", role: .destructive) {
                        session.disconnect()
                    }
                } else if canRetry {
                    Button("Try again") {
                        session.retry()
                    }
                }
            }

            Section("Experience model") {
                Label("See what is on TV", systemImage: "tv")
                Label("Explore what is next", systemImage: "rectangle.stack")
                Label("Share only with intent", systemImage: "hand.tap")
            }

            if !session.events.isEmpty {
                Section("Diagnostics") {
                    ForEach(Array(session.events.suffix(4).reversed())) { event in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.message)
                                .font(.caption)
                            Text(event.timestamp, style: .time)
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .navigationTitle("TV Companion")
    }

    private var sessionHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your session console")
                    .font(.largeTitle.bold())
                Text("Browse and compose privately. Use an explicit action to change the TV.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Label(isConnected ? "LIVE" : "PREVIEW", systemImage: isConnected ? "dot.radiowaves.left.and.right" : "eye")
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isConnected ? Color.green.opacity(0.14) : Color.secondary.opacity(0.12), in: Capsule())
                .foregroundStyle(isConnected ? .green : .secondary)
        }
    }

    private var stagePreview: some View {
        let card = activeCard
        let color = PresentationTheme.color(named: card.colorName)

        return HStack(spacing: 28) {
            Image(systemName: card.symbol)
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 104, height: 104)
                .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 26))

            VStack(alignment: .leading, spacing: 10) {
                Text("NOW ON TV · \(card.eyebrow)")
                    .font(.caption.bold())
                    .foregroundStyle(color)
                Text(card.title)
                    .font(.title.bold())
                Text(card.subtitle)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Label("\(session.presentation.reactionCount) applauses", systemImage: "hands.clap.fill")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(color)
            }
            Spacer()
        }
        .padding(28)
        .background(.background, in: RoundedRectangle(cornerRadius: 30))
        .overlay {
            RoundedRectangle(cornerRadius: 30)
                .stroke(session.presentation.isSpotlightOn ? color : Color.secondary.opacity(0.15), lineWidth: session.presentation.isSpotlightOn ? 4 : 1)
        }
    }

    private var controlDeck: some View {
        HStack(spacing: 16) {
            Button {
                session.send(.previousCard)
            } label: {
                Label("Previous", systemImage: "backward.end.fill")
            }
            .buttonStyle(.bordered)

            Button {
                session.send(.addReaction)
            } label: {
                Label("Applaud", systemImage: "hands.clap.fill")
            }
            .buttonStyle(.borderedProminent)

            Button {
                session.send(.nextCard)
            } label: {
                Label("Next", systemImage: "forward.end.fill")
            }
            .buttonStyle(.bordered)

            Spacer()

            Toggle("Spotlight", isOn: Binding(
                get: { session.presentation.isSpotlightOn },
                set: { session.send(.setSpotlight($0)) }
            ))
            .fixedSize()
        }
        .controlSize(.large)
        .disabled(!isConnected)
    }

    private var momentQueue: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeading(
                "Explore what is next",
                subtitle: "Selecting a moment is private until you choose Put on TV."
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 14)], spacing: 14) {
                ForEach(Array(PresentationState.cards.enumerated()), id: \.offset) { index, card in
                    queueCard(card, index: index)
                }
            }
        }
        .padding(24)
        .background(.background, in: RoundedRectangle(cornerRadius: 28))
    }

    private func queueCard(_ card: PresentationCard, index: Int) -> some View {
        let isActive = session.presentation.selectedCard == index
        let color = PresentationTheme.color(named: card.colorName)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: card.symbol)
                    .foregroundStyle(color)
                Spacer()
                if isActive {
                    Text("ON TV")
                        .font(.caption2.bold())
                        .foregroundStyle(color)
                }
            }
            Text(card.eyebrow)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(card.title)
                .font(.headline)
                .lineLimit(2)
            Spacer(minLength: 4)
            Button(isActive ? "Currently showing" : "Put on TV") {
                session.send(.selectCard(index))
            }
            .buttonStyle(.borderedProminent)
            .tint(color)
            .disabled(!isConnected || isActive)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .leading)
        .background(color.opacity(isActive ? 0.14 : 0.06), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(isActive ? color : Color.clear, lineWidth: 2))
    }

    private var privateComposer: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeading(
                "Compose privately",
                subtitle: "This draft stays on the iPad until you explicitly share it."
            )

            TextField("A short message for everyone in the room", text: $draftMessage, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)

            HStack {
                Label("PRIVATE DRAFT", systemImage: "lock.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text("\(draftMessage.count)/\(CompanionProtocolVersion.maximumSharedMessageLength)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
                Spacer()
                if !session.presentation.sharedMessage.isEmpty {
                    Button("Clear from TV") {
                        session.send(.setSharedMessage(""))
                    }
                    .buttonStyle(.bordered)
                }
                Button("Share on TV") {
                    session.send(.setSharedMessage(draftMessage))
                }
                .buttonStyle(.borderedProminent)
            }
            .disabled(!isConnected)
        }
        .padding(24)
        .background(.background, in: RoundedRectangle(cornerRadius: 28))
    }

    private func sectionHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.bold())
            Text(subtitle)
                .foregroundStyle(.secondary)
        }
    }

    private var activeCard: PresentationCard {
        PresentationState.cards[session.presentation.selectedCard]
    }

    private var canRetry: Bool {
        if case .failed = session.phase { return true }
        return false
    }

    private var connectionSymbol: String {
        if isConnected { return "checkmark.circle.fill" }
        if case .failed = session.phase { return "exclamationmark.triangle.fill" }
        return "antenna.radiowaves.left.and.right"
    }
}
