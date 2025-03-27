import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultSortOrder") private var defaultSortOrder = "newestFirst"
    @State private var isShowingTermsOfService = false
    @State private var isShowingPrivacyPolicy = false
    @State private var isShowingTutorial = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Preferences")) {
                    Picker("Default Sort Order", selection: $defaultSortOrder) {
                        Text("Newest First").tag("newestFirst")
                        Text("Oldest First").tag("oldestFirst")
                        Text("A to Z").tag("alphabeticalAscending")
                        Text("Z to A").tag("alphabeticalDescending")
                    }
                }
                
                Section(header: Text("Support")) {
                    Button(action: { isShowingTutorial = true }) {
                        Label("App Overview", systemImage: "book")
                    }
                    
                    Link(destination: URL(string: "mailto:arunguruswamy22@gmail.com")!) {
                        Label("Contact Us", systemImage: "envelope")
                    }
                }
                
                Section(header: Text("About")) {
                    Button(action: { isShowingTermsOfService = true }) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    
                    Button(action: { isShowingPrivacyPolicy = true }) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $isShowingTermsOfService) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $isShowingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $isShowingTutorial) {
                TutorialView()
            }
        }
    }
}

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    
    let tutorialSteps = [
        TutorialStep(
            title: "Welcome to Word Vault",
            description: "Let's learn how to use Word Vault to build your vocabulary!",
            image: "book.fill"
        ),
        TutorialStep(
            title: "Adding Words or Phrases",
            description: "Tap the + button to add new words or phrases. You can add notes, and organize them into collections.",
            image: "plus.circle.fill"
        ),
        TutorialStep(
            title: "Word Details",
            description: "Tap any word to view its details, including definitions, examples, and your personal notes.",
            image: "text.book.closed.fill"
        ),
        TutorialStep(
            title: "Organizing Words",
            description: "Create collections to organize your words by topic or category. Mark words as favorites for quick access. Clicking on the menu button in the top left corner lets you manage collections.",
            image: "folder.fill"
        ),
        TutorialStep(
            title: "Learning Mode",
            description: "Use the brain icon to access learning modes. Practice writing definitions or using the words in sentences and get AI feedback to improve your understanding.",
            image: "brain.head.profile"
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: tutorialSteps[currentStep].image)
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding()
                
                Text(tutorialSteps[currentStep].title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(tutorialSteps[currentStep].description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                HStack {
                    ForEach(0..<tutorialSteps.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? Color.blue : Color.gray.opacity(0.3))
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
                        .buttonStyle(.bordered)
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
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom)
            }
            .navigationBarItems(trailing: Button("Skip") {
                dismiss()
            })
        }
    }
}

struct TutorialStep {
    let title: String
    let description: String
    let image: String
}

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms of Service")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Last updated: March 2025")
                        .foregroundColor(.secondary)
                    
                    Text("Welcome to Word Vault! By using our app, you agree to these terms.")
                    
                    Group {
                        Text("1. Acceptance of Terms")
                            .font(.headline)
                        Text("By accessing and using Word Vault, you accept and agree to be bound by the terms and provision of this agreement.")
                        
                        Text("2. Use License")
                            .font(.headline)
                        Text("Permission is granted to temporarily download one copy of Word Vault for personal, non-commercial use only.")
                        
                        Text("3. Disclaimer")
                            .font(.headline)
                        Text("The materials on Word Vault are provided on an 'as is' basis. Word Vault makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.")
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Last updated: March 2025")
                        .foregroundColor(.secondary)
                    
                    Text("Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your personal information.")
                    
                    Group {
                        Text("1. Information Collection")
                            .font(.headline)
                        Text("We collect information that you provide directly to us when using Word Vault, including words, phrases, and notes you save.")
                        
                        Text("2. Data Storage")
                            .font(.headline)
                        Text("All your data is stored locally on your device. We do not store any personal information on our servers.")
                        
                        Text("3. Third-Party Services")
                            .font(.headline)
                        Text("We use third-party services for dictionary definitions. These services may collect usage data according to their own privacy policies.")
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
