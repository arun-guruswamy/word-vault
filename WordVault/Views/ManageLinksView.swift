import SwiftUI
import SwiftData

struct ManageLinksView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // The Word being managed
    @Bindable var word: Word // Changed from itemWrapper
    
    // All words for searching
    @Query(sort: \Word.wordText) private var allWords: [Word]
    
    @State private var searchText = ""
    
    // All other words for searching
    private var otherWords: [Word] {
        allWords.filter { $0.id != word.id } // Exclude the item itself
    }
    
    // Filtered words based on search text
    private var filteredWords: [Word] {
        if searchText.isEmpty {
            return otherWords
        } else {
            return otherWords.filter { $0.wordText.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // Words currently linked to the main word
    private var linkedWords: [Word] {
        otherWords.filter { word.linkedItemIDs.contains($0.id) }
    }
    
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
                    // Section for Currently Linked Items
                    Section("Currently Linked") {
                        if linkedWords.isEmpty {
                            Text("No words linked yet.")
                                .font(.custom("Marker Felt", size: 16))
                                .foregroundColor(.gray)
                        } else {
                            ForEach(linkedWords) { linkedWord in
                                HStack {
                                    Text(linkedWord.wordText)
                                        .font(.custom("Marker Felt", size: 16))
                                    Spacer()
                                    Button("Unlink") {
                                        unlinkItem(linkedWord)
                                    }
                                    .font(.custom("Marker Felt", size: 14))
                                    .foregroundColor(.red)
                                    .buttonStyle(.borderless) // Use borderless for list buttons
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.7))
                    
                    // Section for Adding New Links
                    Section("Link New Words") {
                        ForEach(filteredWords) { potentialLinkWord in
                            // Only show words that are not already linked
                            if !word.linkedItemIDs.contains(potentialLinkWord.id) {
                                HStack {
                                    Text(potentialLinkWord.wordText)
                                        .font(.custom("Marker Felt", size: 16))
                                    Spacer()
                                    Button("Link") {
                                        linkItem(potentialLinkWord)
                                    }
                                    .font(.custom("Marker Felt", size: 14))
                                    .foregroundColor(.blue)
                                    .buttonStyle(.borderless)
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.7))
                }
                .searchable(text: $searchText, prompt: "Search words to link")
                .scrollContentBackground(.hidden) // Make list background transparent
            }
            .navigationTitle("Manage Links for \"\(word.wordText)\"")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.custom("Marker Felt", size: 16))
                    .foregroundColor(.black)
                }
            }
        }
    }
    
    // Helper function to link an item
    private func linkItem(_ wordToLink: Word) {
        // Add to both words' linked lists for bidirectional linking
        if !word.linkedItemIDs.contains(wordToLink.id) {
            word.linkedItemIDs.append(wordToLink.id)
        }
        if !wordToLink.linkedItemIDs.contains(word.id) {
            wordToLink.linkedItemIDs.append(word.id)
        }
        try? modelContext.save()
    }
    
    // Helper function to unlink an item
    private func unlinkItem(_ wordToUnlink: Word) {
        // Remove from both words' linked lists
        word.linkedItemIDs.removeAll { $0 == wordToUnlink.id }
        wordToUnlink.linkedItemIDs.removeAll { $0 == word.id }
        try? modelContext.save()
    }
}

// #Preview {
// // Need a way to create a sample item for preview
// }
