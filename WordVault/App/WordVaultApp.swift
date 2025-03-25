import SwiftUI
import SwiftData

@main
struct WordVaultApp: App {
    // App group identifier for shared container
    private let appGroupIdentifier = "group.com.arun-guruswamy.WordVault"
    
    var sharedModelContainer: ModelContainer = {
        do {
            let schema = Schema([
                Word.self,
                Phrase.self,
                Collection.self
            ])
            
            // Create model configuration with app group container
            let modelConfiguration = ModelConfiguration(
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .identifier("group.com.arun-guruswamy.WordVault")
            )
            
            print("Using shared app group container: group.com.arun-guruswamy.WordVault")
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
