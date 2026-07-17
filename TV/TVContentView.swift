import DeviceDiscoveryUI
import SwiftUI

struct TVContentView: View {
    @EnvironmentObject private var session: TVSessionModel
    @State private var isShowingDevicePicker = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, activeColor.opacity(0.32), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 34) {
                header
                sharedStage
                sharedMessage
                connectionDock
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 58)
        }
        .fullScreenCover(isPresented: $isShowingDevicePicker) {
            DevicePicker(
                .applicationService(name: CompanionService.identifier)
            ) { endpoint in
                session.connect(to: endpoint)
                isShowingDevicePicker = false
            } label: {
                Label("Choose an iPad", systemImage: "ipad.and.iphone")
            } fallback: {
                ContentUnavailableView(
                    "Pairing unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text("TV Companion Kit requires a supported Apple TV 4K for device discovery.")
                )
            } parameters: {
                .applicationService
            }
        }
    }

    private var active: PresentationCard {
        PresentationState.cards[session.presentation.selectedCard]
    }

    private var activeColor: Color {
        PresentationTheme.color(named: active.colorName)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "tv.and.hifispeaker.fill")
                        .foregroundStyle(activeColor)
                    Text("TV COMPANION KIT")
                }
                .font(.headline.bold())

                Text("The TV is the shared stage")
                    .font(.system(size: 46, weight: .bold))
            }

            Spacer()

            Label(
                session.phase == .connected ? "iPad connected" : "TV continues independently",
                systemImage: session.phase == .connected ? "checkmark.circle.fill" : "tv"
            )
            .font(.headline)
            .foregroundStyle(session.phase == .connected ? .green : .secondary)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: Capsule())
        }
    }

    private var sharedStage: some View {
        HStack(spacing: 52) {
            Image(systemName: active.symbol)
                .font(.system(size: 104, weight: .semibold))
                .foregroundStyle(activeColor)
                .frame(width: 190, height: 190)
                .background(activeColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 44))

            VStack(alignment: .leading, spacing: 18) {
                Text("\(active.eyebrow) · \(session.presentation.selectedCard + 1) OF \(PresentationState.cards.count)")
                    .font(.headline.bold())
                    .foregroundStyle(activeColor)

                Text(active.title)
                    .font(.system(size: 64, weight: .bold))
                    .minimumScaleFactor(0.8)

                Text(active.subtitle)
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Label(active.takeaway, systemImage: "lightbulb.fill")
                    .font(.title3.bold())
                    .foregroundStyle(activeColor)
                    .padding(.top, 6)
            }

            Spacer(minLength: 12)

            VStack(spacing: 8) {
                Image(systemName: "hands.clap.fill")
                    .font(.title)
                Text(session.presentation.reactionCount.formatted())
                    .font(.system(size: 38, weight: .bold, design: .rounded).monospacedDigit())
                Text("APPLAUSE")
                    .font(.caption.bold())
            }
            .foregroundStyle(activeColor)
            .padding(24)
            .background(activeColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 28))
        }
        .padding(48)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 42))
        .overlay {
            RoundedRectangle(cornerRadius: 42)
                .stroke(session.presentation.isSpotlightOn ? activeColor : Color.white.opacity(0.08), lineWidth: session.presentation.isSpotlightOn ? 7 : 1)
                .shadow(color: session.presentation.isSpotlightOn ? activeColor.opacity(0.7) : .clear, radius: 24)
        }
        .animation(.snappy, value: session.presentation)
    }

    @ViewBuilder
    private var sharedMessage: some View {
        if !session.presentation.sharedMessage.isEmpty {
            HStack(spacing: 18) {
                Image(systemName: "ipad.and.arrow.forward")
                    .foregroundStyle(activeColor)
                VStack(alignment: .leading, spacing: 4) {
                    Text("SHARED FROM THE IPAD")
                        .font(.caption.bold())
                        .foregroundStyle(activeColor)
                    Text(session.presentation.sharedMessage)
                        .font(.title2)
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var connectionDock: some View {
        VStack(spacing: 14) {
            HStack(spacing: 24) {
                if session.phase == .connected {
                    Label("Private console active", systemImage: "ipad")
                        .font(.headline)
                    Text("Browse, compose, and choose what appears here from the iPad.")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Disconnect", role: .destructive) {
                        session.disconnect()
                    }
                } else {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Add a private session console")
                            .font(.headline)
                        Text("Open TV Companion on an iPad, then connect it from this TV.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        isShowingDevicePicker = true
                    } label: {
                        Label("Connect an iPad", systemImage: "ipad.and.iphone")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(activeColor)
                }
            }

            if let event = session.events.last {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                    Text(event.message)
                    Spacer()
                    Text("r\(session.revision)")
                }
                .font(.caption.monospaced())
                .foregroundStyle(.tertiary)
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 28))
    }
}
