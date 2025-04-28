import SwiftUI
import SwiftData

import SwiftUI
import SwiftData

@main
struct WordLockerApp: App {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    @State private var showTutorial: Bool = false

    // Removed service StateObjects

    // Removed sharedModelContainer definition.
    // Relying on the default .modelContainer modifier below and Xcode capabilities.

    var body: some Scene {
        WindowGroup {
            HomeView()
                .onAppear {
                    if !hasLaunchedBefore {
                        showTutorial = true
                    }
                }
                .sheet(isPresented: $showTutorial) {
                    // Set hasLaunchedBefore to true when the sheet is dismissed
                    hasLaunchedBefore = true
                } content: {
                    // Need to embed TutorialView in a NavigationView or similar
                    // to get the dismiss button functionality if it relies on Environment(\.dismiss)
                    // Let's reuse the structure from SettingsView for consistency
                    TutorialView()
                }
                // Removed environmentObject injections
        }
        // Use the simpler modifier. SwiftData will create a default container.
        // If iCloud capability is enabled in Xcode, it should default to using CloudKit.
        .modelContainer(for: [Word.self, Phrase.self, Collection.self])
    }
}
