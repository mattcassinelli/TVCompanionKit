import SwiftUI

enum PresentationTheme {
    static func color(named name: String) -> Color {
        switch name {
        case "cyan": .cyan
        case "indigo": .indigo
        case "orange": .orange
        case "mint": .mint
        default: .cyan
        }
    }
}
