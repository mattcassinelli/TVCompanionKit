import SwiftUI

@main
struct TVCompanionPadApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var session = PadSessionModel()

    var body: some Scene {
        WindowGroup {
            PadContentView()
                .environmentObject(session)
                .task { session.startListening() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        session.ensureListening()
                    }
                }
        }
    }
}
