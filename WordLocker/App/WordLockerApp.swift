import SwiftUI
import SwiftData

import SwiftUI
import SwiftData

@main
struct WordLockerApp: App {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    @State private var showTutorial: Bool = false

    // Removed service StateObjects

    // App group identifier for shared container
    private let appGroupIdentifier = "group.com.arun-guruswamy.WordLocker1"
    
    var sharedModelContainer: ModelContainer = {
        do {
            let schema = Schema([
                Word.self,
                Phrase.self,
                Collection.self
            ])

            // Define identifiers
            let appGroupID = "group.com.arun-guruswamy.WordLocker1"
            let cloudKitContainerID = "iCloud.com.arun-guruswamy.WordLocker1" // Derived from Bundle ID

            // Create configuration for App Group (local storage)
            let appGroupConfiguration = ModelConfiguration(
                "LocalData", // Give it a name
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .identifier(appGroupID)
            )

            // --- CloudKit Configuration (Commented Out) ---
            /*
            let cloudKitConfiguration = ModelConfiguration(
                "CloudData", // Give it a name
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .identifier(appGroupID), // Can share the same group container
                cloudKitDatabase: .automatic // Use automatic private database
                // cloudKitContainerIdentifier is inferred from entitlements
            )
            */
            // --- End CloudKit Configuration ---

            print("Using App Group container: \(appGroupID)")
            // print("Using CloudKit container: \(cloudKitContainerID)") // Commented out CloudKit log

            // Pass ONLY the App Group configuration to the ModelContainer
            // CloudKit syncing is disabled for now
            return try ModelContainer(for: schema, configurations: [appGroupConfiguration]) // Removed cloudKitConfiguration
        } catch {
            // Provide more context in the fatal error
            fatalError("Could not create ModelContainer. Error: \(error). Check App Group and CloudKit configurations/entitlements.")
        }
    }()

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
        .modelContainer(sharedModelContainer)
    }
}
