import SwiftUI
import CloudKit // For account status
import Network // For network monitoring

// Helper class to manage NWPathMonitor lifecycle
class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    @Published var isConnected = true // Default to true, update on change

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

struct SettingsView: View {
    @AppStorage("defaultSortOrder") private var defaultSortOrder = "newestFirst"
    @State private var iCloudStatus: CKAccountStatus = .couldNotDetermine // State for iCloud status
    @StateObject private var networkMonitor = NetworkMonitor() // Monitor network status
    @State private var isShowingTutorial = false
    @State private var isShowingPremium = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Background color matching the app
                Color(red: 0.86, green: 0.75, blue: 0.6)
                    .ignoresSafeArea()
                    .overlay(
                        Image(systemName: "circle.grid.cross.fill")
                            .foregroundColor(.brown.opacity(0.1))
                            .font(.system(size: 20))
                    )
                
                List {
                    Section {
                        Picker("Default Sort Order", selection: $defaultSortOrder) {
                            Text("Newest First").tag("newestFirst")
                            Text("Oldest First").tag("oldestFirst")
                            Text("A to Z").tag("alphabeticalAscending")
                            Text("Z to A").tag("alphabeticalDescending")
                        }
                        .pickerStyle(.menu)
                        .font(.custom("Marker Felt", size: 16))
                    } header: {
                        Text("Preferences")
                            .font(.custom("Marker Felt", size: 18))
                            .foregroundColor(.black)
                    }
                    .listRowBackground(Color.white.opacity(0.7))
                    
                    Section {
                        Button(action: { isShowingTutorial = true }) {
                            HStack {
                                Image(systemName: "book")
                                    .foregroundColor(.black)
                                Text("App Overview")
                                    .font(.custom("Marker Felt", size: 16))
                                    .foregroundColor(.black)
                            }
                        }

//                        Button(action: { isShowingPremium = true }) {
//                            HStack {
//                                Image(systemName: "star")
//                                    .foregroundColor(.black)
//                                Text("Premium")
//                                    .font(.custom("Marker Felt", size: 16))
//                                    .foregroundColor(.black)
//                            }
//                        }

                        Link(destination: URL(string: "mailto:arunguruswamy22@gmail.com")!) {
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.black)
                                Text("Contact Us")
                                    .font(.custom("Marker Felt", size: 16))
                                    .foregroundColor(.black)
                            }
                        }
                    } header: {
                        Text("Support")
                            .font(.custom("Marker Felt", size: 18))
                            .foregroundColor(.black)
                    }
                    .listRowBackground(Color.white.opacity(0.7))

                    Section {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundColor(.black)
                            Link("Privacy Policy", destination: URL(string: "https://arun-guruswamy.github.io/personal-portfolio/word-Locker-privacy")!)
                                .font(.custom("Marker Felt", size: 16))
                                .foregroundColor(.black)
                        }
                        
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.black)
                            Text("Version")
                                .font(.custom("Marker Felt", size: 16))
                                .foregroundColor(.black)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                                .font(.custom("Marker Felt", size: 16))
                                .foregroundColor(.gray)
                        }
                    } header: {
                        Text("About")
                            .font(.custom("Marker Felt", size: 18))
                            .foregroundColor(.black)
                    }
                    .listRowBackground(Color.white.opacity(0.7))

                    // --- iCloud Sync Status Section ---
                    Section {
                        // Combine iCloud account status and network status
                        switch (iCloudStatus, networkMonitor.isConnected) {
                        case (.available, true):
                            // Account available and network connected
                            HStack {
                                Image(systemName: "icloud.fill")
                                    .foregroundColor(.blue)
                                Text("iCloud Syncing Active")
                                    .font(.custom("Marker Felt", size: 16))
                                    .foregroundColor(.black)
                            }
                        case (.available, false):
                            // Account available but no network connection for syncing
                            HStack {
                                Image(systemName: "icloud.slash.fill")
                                    .foregroundColor(.gray)
                                Text("Sync Paused - Waiting for Connection")
                                    .font(.custom("Marker Felt", size: 16))
                                    .foregroundColor(.gray)
                            }
                        case (.noAccount, _):
                            // Handle noAccount specifically
                            HStack {
                                Image(systemName: "exclamationmark.icloud.fill")
                                    .foregroundColor(.orange)
                                Text("iCloud sync disabled. Check iCloud settings for Word Locker in the device Settings app.")
                                    .font(.custom("Marker Felt", size: 16))
                                    .foregroundColor(.black)
                            }
                        case (.restricted, _):
                             // Handle restricted specifically
                             HStack {
                                 Image(systemName: "xmark.icloud.fill")
                                     .foregroundColor(.red)
                                 Text("iCloud sync disabled. Check iCloud settings for Word Locker in the device Settings app.")
                                     .font(.custom("Marker Felt", size: 16))
                                     .foregroundColor(.black)
                             }
                        case (.couldNotDetermine, _):
                            // Status couldn't be determined yet
                            HStack {
                                Image(systemName: "questionmark.icloud.fill")
                                    .foregroundColor(.gray)
                                Text("Checking iCloud status...")
                                    .font(.custom("Marker Felt", size: 16))
                                    .foregroundColor(.gray)
                            }
                        @unknown default:
                             // Use the same UI as restricted for any other unexpected states
                             HStack {
                                 Image(systemName: "xmark.icloud.fill")
                                     .foregroundColor(.red)
                                 Text("iCloud sync disabled due to an unknown status. Check iCloud settings.")
                                     .font(.custom("Marker Felt", size: 16))
                                     .foregroundColor(.black)
                             }
                        }
                    } header: {
                        Text("iCloud Sync")
                            .font(.custom("Marker Felt", size: 18))
                            .foregroundColor(.black)
                    }
                    .listRowBackground(Color.white.opacity(0.7))
                    // --- End iCloud Sync Status Section ---

                }
                .scrollContentBackground(.hidden)
                .onAppear(perform: checkiCloudStatus) // Check status when view appears
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.custom("Marker Felt", size: 20))
                        .foregroundColor(.black)
                }
            }
            .sheet(isPresented: $isShowingTutorial) {
                TutorialView()
            }
            .sheet(isPresented: $isShowingPremium) {
                PremiumView()
            }
        }
        .accentColor(.black) // Set back button color to black
    }

    // Function to check iCloud account status
    private func checkiCloudStatus() {
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error checking iCloud status: \(error.localizedDescription)")
                    self.iCloudStatus = .couldNotDetermine // Keep as undetermined on error
                } else {
                    self.iCloudStatus = status
                }
            }
        }
    }
}

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    
    let tutorialSteps = [
        TutorialStep(
            title: "Welcome to Word Locker",
            description: "Let's learn how to use Word Locker to build your vocabulary and store your favorite words or phrases!",
            image: "book.fill"
        ),
        TutorialStep(
            title: "Adding Words or Phrases in the app",
            description: "Tap the + button to add new words or phrases. You can add notes, and organize them into collections.\n\nThe app automatically distinguishes between words and phrases based on whether there are any space separated characters in your input.",
            image: "plus.circle.fill"
        ),
//        TutorialStep(
//            title: "Adding Words or Phrases from other apps",
//            description: "You can also add words or phrases by highlighting them in other apps, and then sharing to the Word Locker app. The app automatically stores the text shared",
//            image: "shareWord"
//        ),
        TutorialStep(
            title: "Word Details",
        description: "Tap any word to view its details, including its definitions, pronounciation, examples, your personal notes, and even a fun fact!",
            image: "text.book.closed.fill"
        ),
        TutorialStep(
            title: "Interacting with Words",
        description: "Words can be marked as favorite or confident by clicking the respective toggle buttons underneath the word. Click on the speaker icon to hear the word's pronounciation! (If phone is not on silent)",
            image: "WordTitle"
        ),
        TutorialStep(
            title: "Phrase Details",
        description: "Tap a phrase to view any personal notes you recorded, and an AI's interpretation of the phrase's meaning and potential significance!",
            image: "text.book.closed.fill"
        ),
        TutorialStep(
            title: "Organizing Words and Phrases",
            description: "Create collections to organize your words by topic or category. Mark words as favorites for quick access. Clicking on the menu button in the top left corner lets you manage collections.",
            image: "folder.fill"
        ),
        TutorialStep(
            title: "Learning Words",
            description: "Use the brain icon to access learning modes. Practice writing definitions or using the words in sentences and get AI feedback to improve your understanding. Once you are confident with a word, you can mark that you are confident in it!",
            image: "brain.head.profile"
        ),
        TutorialStep(
            title: "Linking Words",
            description: "Connect related words! In a word's detail view, go to the 'Links' tab and tap 'Manage Links' to manage connections to other words.",
            image: "link"
        ),
        TutorialStep(
            title: "Hope you enjoy using the app!",
            description: "",
            image: "sparkles"
        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color matching the app
                Color(red: 0.86, green: 0.75, blue: 0.6)
                    .ignoresSafeArea()
                    .overlay(
                        Image(systemName: "circle.grid.cross.fill")
                            .foregroundColor(.brown.opacity(0.1))
                            .font(.system(size: 20))
                    )
                
                VStack(spacing: 30) {
                    if (tutorialSteps[currentStep].title == "Adding Words or Phrases from other apps") {
                        Image(tutorialSteps[currentStep].image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                            .foregroundColor(.brown)
                            .padding()
                    }
                    else if (tutorialSteps[currentStep].title == "Interacting with Words") {
                        Image(tutorialSteps[currentStep].image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                            .foregroundColor(.brown)
                            .padding()
                    }
                    else {
                        Image(systemName: tutorialSteps[currentStep].image)
                            .font(.system(size: 60))
                            .foregroundColor(.brown)
                            .padding()
                    }
                    
                    Text(tutorialSteps[currentStep].title)
                        .font(.custom("Marker Felt", size: 24))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    
                    Text(tutorialSteps[currentStep].description)
                        .font(.custom("Inter-Regular", size: 16))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    HStack {
                        ForEach(0..<tutorialSteps.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentStep ? Color.brown : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.bottom)
                    
                    HStack(spacing: 20) {
                        if currentStep > 0 {
                            Button("Previous") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .font(.custom("Marker Felt", size: 16))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.9))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(Color.black, lineWidth: 2)
                                    )
                            )
                            .foregroundColor(.black)
                        }
                        
                        Button(currentStep == tutorialSteps.count - 1 ? "Done" : "Next") {
                            if currentStep == tutorialSteps.count - 1 {
                                dismiss()
                            } else {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                        }
                        .font(.custom("Marker Felt", size: 16))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.brown.opacity(0.8))
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                        )
                        .foregroundColor(.white)
                    }
                    .padding(.bottom, 30)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                    .font(.custom("Marker Felt", size: 16))
                    .foregroundColor(.black)
                }
            }
        }
    }
}

struct TutorialStep {
    let title: String
    let description: String
    let image: String
}
