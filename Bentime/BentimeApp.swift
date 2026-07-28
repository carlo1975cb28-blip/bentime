import SwiftUI

@main
struct BentimeApp: App {
    @StateObject private var playerViewModel = PlayerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playerViewModel)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open File...") {
                    playerViewModel.openFilePanel()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Open Subtitle File...") {
                    playerViewModel.openSubtitleFilePanel()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }
}
