import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultSortOrder") private var defaultSortOrder = "newestFirst"
    @State private var isShowingTermsOfService = false
    @State private var isShowingPrivacyPolicy = false
    @State private var isShowingTutorial = false
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
                        Button(action: { isShowingTermsOfService = true }) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.black)
                                Text("Terms of Service")
                                    .font(.custom("Marker Felt", size: 16))
                                    .foregroundColor(.black)
                            }
                        }
                        
                        Button(action: { isShowingPrivacyPolicy = true }) {
                            HStack {
                                Image(systemName: "hand.raised")
                                    .foregroundColor(.black)
                                Text("Privacy Policy")
                                    .font(.custom("Marker Felt", size: 16))
                                    .foregroundColor(.black)
                            }
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
                }
                .scrollContentBackground(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.custom("Marker Felt", size: 20))
                        .foregroundColor(.black)
                }
            }
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
                    Image(systemName: tutorialSteps[currentStep].image)
                        .font(.system(size: 60))
                        .foregroundColor(.brown)
                        .padding()
                    
                    Text(tutorialSteps[currentStep].title)
                        .font(.custom("Marker Felt", size: 24))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    
                    Text(tutorialSteps[currentStep].description)
                        .font(.custom("BradleyHandITCTT-Bold", size: 16))
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

struct TermsOfServiceView: View {
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Terms of Service")
                            .font(.custom("Marker Felt", size: 24))
                            .foregroundColor(.black)
                        
                        Text("Last updated: March 2025")
                            .font(.custom("BradleyHandITCTT-Bold", size: 14))
                            .foregroundColor(.gray)
                        
                        Text("Welcome to Word Vault! By using our app, you agree to these terms.")
                            .font(.custom("BradleyHandITCTT-Bold", size: 16))
                            .foregroundColor(.black)
                        
                        Group {
                            Text("1. Acceptance of Terms")
                                .font(.custom("Marker Felt", size: 18))
                                .foregroundColor(.black)
                            
                            Text("By accessing and using Word Vault, you accept and agree to be bound by the terms and provision of this agreement.")
                                .font(.custom("BradleyHandITCTT-Bold", size: 16))
                                .foregroundColor(.black)
                            
                            Text("2. Use License")
                                .font(.custom("Marker Felt", size: 18))
                                .foregroundColor(.black)
                            
                            Text("Permission is granted to temporarily download one copy of Word Vault for personal, non-commercial use only.")
                                .font(.custom("BradleyHandITCTT-Bold", size: 16))
                                .foregroundColor(.black)
                            
                            Text("3. Disclaimer")
                                .font(.custom("Marker Felt", size: 18))
                                .foregroundColor(.black)
                            
                            Text("The materials on Word Vault are provided on an 'as is' basis. Word Vault makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.")
                                .font(.custom("BradleyHandITCTT-Bold", size: 16))
                                .foregroundColor(.black)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .padding()
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { 
                        dismiss() 
                    }
                    .font(.custom("Marker Felt", size: 16))
                    .foregroundColor(.black)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Terms of Service")
                        .font(.custom("Marker Felt", size: 20))
                        .foregroundColor(.black)
                }
            }
        }
    }
}

struct PrivacyPolicyView: View {
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Privacy Policy")
                            .font(.custom("Marker Felt", size: 24))
                            .foregroundColor(.black)
                        
                        Text("Last updated: March 2025")
                            .font(.custom("BradleyHandITCTT-Bold", size: 14))
                            .foregroundColor(.gray)
                        
                        Text("Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your personal information.")
                            .font(.custom("BradleyHandITCTT-Bold", size: 16))
                            .foregroundColor(.black)
                        
                        Group {
                            Text("1. Information Collection")
                                .font(.custom("Marker Felt", size: 18))
                                .foregroundColor(.black)
                            
                            Text("We collect information that you provide directly to us when using Word Vault, including words, phrases, and notes you save.")
                                .font(.custom("BradleyHandITCTT-Bold", size: 16))
                                .foregroundColor(.black)
                            
                            Text("2. Data Storage")
                                .font(.custom("Marker Felt", size: 18))
                                .foregroundColor(.black)
                            
                            Text("All your data is stored locally on your device. We do not store any personal information on our servers.")
                                .font(.custom("BradleyHandITCTT-Bold", size: 16))
                                .foregroundColor(.black)
                            
                            Text("3. Third-Party Services")
                                .font(.custom("Marker Felt", size: 18))
                                .foregroundColor(.black)
                            
                            Text("We use third-party services for dictionary definitions. These services may collect usage data according to their own privacy policies.")
                                .font(.custom("BradleyHandITCTT-Bold", size: 16))
                                .foregroundColor(.black)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .padding()
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { 
                        dismiss() 
                    }
                    .font(.custom("Marker Felt", size: 16))
                    .foregroundColor(.black)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Privacy Policy")
                        .font(.custom("Marker Felt", size: 20))
                        .foregroundColor(.black)
                }
            }
        }
    }
}
