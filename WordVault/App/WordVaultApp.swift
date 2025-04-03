import SwiftUI
import SwiftData

@main
struct WordVaultApp: App {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    @State private var showTutorial: Bool = false

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
        }
        .modelContainer(sharedModelContainer)
    }
}
