import SwiftUI

@main
struct TVCompanionTVApp: App {
    @StateObject private var session = TVSessionModel()

    var body: some Scene {
        WindowGroup {
            TVContentView()
                .environmentObject(session)
        }
    }
}
