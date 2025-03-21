import SwiftUI
import SwiftData

@main
struct WordVaultApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Word.self,
            Phrase.self,
            Collection.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
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
