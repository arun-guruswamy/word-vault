import SwiftUI

struct SettingsView: View {
    @AppStorage("enableHapticFeedback") private var enableHapticFeedback = true
    @AppStorage("enableAutoDefinition") private var enableAutoDefinition = true
    @AppStorage("defaultSortOrder") private var defaultSortOrder = "dateAdded"
    @State private var isShowingTermsOfService = false
    @State private var isShowingPrivacyPolicy = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Preferences")) {
                    Toggle("Haptic Feedback", isOn: $enableHapticFeedback)
                    Toggle("Auto-fetch Definitions", isOn: $enableAutoDefinition)
                    
                    Picker("Default Sort Order", selection: $defaultSortOrder) {
                        Text("Date Added").tag("dateAdded")
                        Text("Alphabetical").tag("alphabetical")
                    }
                }
                
                Section(header: Text("Contact")) {
                    Link("Contact Support", destination: URL(string: "mailto:support@wordvault.app")!)
                        .foregroundColor(.primary)
                    
                    Link("Follow us on Twitter", destination: URL(string: "https://twitter.com/wordvault")!)
                        .foregroundColor(.primary)
                }
                
                Section(header: Text("About")) {
                    Button(action: { isShowingTermsOfService = true }) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    
                    Button(action: { isShowingPrivacyPolicy = true }) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    
                    HStack {
                        Text("Version")
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
        }
    }
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
