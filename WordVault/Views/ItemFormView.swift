import SwiftUI
import SwiftData
import Foundation

struct ItemFormView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Collection.createdAt) private var collections: [Collection]
    
    // State variables
    @State private var itemText: String
    @State private var notes: String
    @State private var selectedCollectionNames: Set<String>
    @State private var isFavorite: Bool
    @State private var isConfident: Bool
    @State private var showingDuplicateAlert = false
    
    // Mode and existing items (if editing)
    private let mode: Mode
    private let existingWord: Word?
    private let existingPhrase: Phrase?
    
    enum Mode {
        case add
        case editWord(Word)
        case editPhrase(Phrase)
    }
    
    init(mode: Mode) {
        self.mode = mode
        
        // Initialize state variables based on mode
        switch mode {
        case .add:
            self.existingWord = nil
            self.existingPhrase = nil
            _itemText = State(initialValue: "")
            _notes = State(initialValue: "")
            _selectedCollectionNames = State(initialValue: [])
            _isFavorite = State(initialValue: false)
            _isConfident = State(initialValue: false)
            
        case .editWord(let word):
            self.existingWord = word
            self.existingPhrase = nil
            _itemText = State(initialValue: word.wordText)
            _notes = State(initialValue: word.notes)
            _selectedCollectionNames = State(initialValue: Set(word.collectionNames))
            _isFavorite = State(initialValue: word.isFavorite)
            _isConfident = State(initialValue: word.isConfident)
            
        case .editPhrase(let phrase):
            self.existingWord = nil
            self.existingPhrase = phrase
            _itemText = State(initialValue: phrase.phraseText)
            _notes = State(initialValue: phrase.notes)
            _selectedCollectionNames = State(initialValue: Set(phrase.collectionNames))
            _isFavorite = State(initialValue: phrase.isFavorite)
            _isConfident = State(initialValue: false)
        }
    }
    
    private func isPhrase(_ text: String) -> Bool {
        // Count words in the text
        let words = text.split(separator: " ")
        let isPhrase = words.count > 1
        print("Checking if '\(text)' is a phrase: \(isPhrase) (word count: \(words.count))")
        return isPhrase
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Text Input Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Text")
                                .font(.custom("Marker Felt", size: 20))
                                .foregroundColor(.black)
                            
                            TextField("Enter word or phrase", text: $itemText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.custom("Marker Felt", size: 16))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white.opacity(0.9))
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 3)
                                                .stroke(Color.black.opacity(1), lineWidth: 2)
                                        )
                                )
                        }
                        .padding(.horizontal)
                        
                        // Only show confidence section for words, not phrases
                        if case .editPhrase = mode {
                            // Don't show confidence section for phrases
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Confidence Level")
                                    .font(.custom("Marker Felt", size: 20))
                                    .foregroundColor(.black)
                                
                                Toggle(isOn: $isConfident) {
                                    HStack {
                                        Image(systemName: isConfident ? "checkmark.seal.fill" : "checkmark.seal")
                                            .foregroundColor(isConfident ? .green : .gray)
                                            .imageScale(.large)
                                        Text("I'm confident with this word")
                                            .font(.custom("Marker Felt", size: 16))
                                            .foregroundColor(.black)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .green))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white.opacity(0.9))
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 3)
                                                .stroke(Color.black.opacity(1), lineWidth: 2)
                                        )
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        // Collections Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Collections")
                                .font(.custom("Marker Felt", size: 20))
                                .foregroundColor(.black)
                            
                            VStack(spacing: 8) {
                                Button(action: {
                                    isFavorite.toggle()
                                }) {
                                    HStack {
                                        Text("Favorites")
                                            .font(.custom("Marker Felt", size: 16))
                                            .foregroundColor(.black)
                                        Spacer()
                                        if isFavorite {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                        } else {
                                            Image(systemName: "star")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.white.opacity(0.9))
                                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 3)
                                                    .stroke(Color.black.opacity(1), lineWidth: 2)
                                            )
                                    )
                                }
                                
                                ForEach(collections) { collection in
                                    Button(action: {
                                        if selectedCollectionNames.contains(collection.name) {
                                            selectedCollectionNames.remove(collection.name)
                                        } else {
                                            selectedCollectionNames.insert(collection.name)
                                        }
                                    }) {
                                        HStack {
                                            Text(collection.name)
                                                .font(.custom("Marker Felt", size: 16))
                                                .foregroundColor(.black)
                                            Spacer()
                                            if selectedCollectionNames.contains(collection.name) {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(Color.white.opacity(0.9))
                                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 3)
                                                        .stroke(Color.black.opacity(1), lineWidth: 2)
                                                )
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Notes Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes")
                                .font(.custom("Marker Felt", size: 20))
                                .foregroundColor(.black)
                            
                            TextEditor(text: $notes)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.custom("Marker Felt", size: 16))
                                .lineLimit(5...10)
                                .frame(minHeight: 100)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white.opacity(0.9))
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 3)
                                                .stroke(Color.black.opacity(1), lineWidth: 2)
                                        )
                                )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(navigationTitle)
                .font(.custom("Marker Felt", size: 16))
                .foregroundColor(.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.custom("Marker Felt", size: 16))
                    .foregroundColor(.black)
                }
                ToolbarItem(placement: .principal) {
                    Text(navigationTitle)
                        .font(.custom("Marker Felt", size: 20))
                        .foregroundColor(.black)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            let success = await saveItem()
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .font(.custom("Marker Felt", size: 16))
                    .foregroundColor(.black)
                    .disabled(itemText.isEmpty)
                }
            }
            .alert("Duplicate Item", isPresented: $showingDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This word or phrase already exists in your vault.")
            }
        }
    }
    
    private var navigationTitle: String {
        switch mode {
        case .add:
            return "Add New Item"
        case .editWord:
            return "Edit Word"
        case .editPhrase:
            return "Edit Phrase"
        }
    }
    
    @MainActor
    private func saveItem() async -> Bool {
        // Check for duplicates first
        let existingWords = Word.fetchAll(modelContext: modelContext)
        let existingPhrases = Phrase.fetchAll(modelContext: modelContext)
        
        // Check for duplicates (case-insensitive), excluding the current item being edited
        let isDuplicateWord = existingWords.contains { word in
            // Skip the current word if we're editing it
            if case .editWord(let currentWord) = mode, word.id == currentWord.id {
                return false
            }
            // If we're editing and the text hasn't changed, it's not a duplicate
            if case .editWord(let currentWord) = mode, word.id == currentWord.id && word.wordText.lowercased() == itemText.lowercased() {
                return false
            }
            return word.wordText.lowercased() == itemText.lowercased()
        }
        
        let isDuplicatePhrase = existingPhrases.contains { phrase in
            // Skip the current phrase if we're editing it
            if case .editPhrase(let currentPhrase) = mode, phrase.id == currentPhrase.id {
                return false
            }
            // If we're editing and the text hasn't changed, it's not a duplicate
            if case .editPhrase(let currentPhrase) = mode, phrase.id == currentPhrase.id && phrase.phraseText.lowercased() == itemText.lowercased() {
                return false
            }
            return phrase.phraseText.lowercased() == itemText.lowercased()
        }
        
        if isDuplicateWord || isDuplicatePhrase {
            print("Duplicate item found: \(itemText)")
            showingDuplicateAlert = true
            return false
        }
        
        switch mode {
        case .add:
            if isPhrase(itemText) {
                // Create and save phrase using PhraseService
                let newPhrase = PhraseService.shared.createPhrase(
                    text: itemText,
                    notes: notes,
                    isFavorite: isFavorite,
                    collectionNames: Array(selectedCollectionNames)
                )
                
                await PhraseService.shared.savePhrase(newPhrase, modelContext: modelContext)
                return true
            } else {
                // Create and save word using WordService
                let newWord = await WordService.shared.createWord(
                    text: itemText,
                    notes: notes,
                    isFavorite: isFavorite,
                    isConfident: isConfident,
                    collectionNames: Array(selectedCollectionNames)
                )
                
                await WordService.shared.saveWord(newWord, modelContext: modelContext)
                return true
            }
            
        case .editWord(let word):
            if itemText != word.wordText {
                // Update word text first
                word.wordText = itemText
                word.meanings = []
                word.audioURL = nil
                try? modelContext.save()
                
                // Populate word content using WordService
                Task {
                    await WordService.shared.populateWordContent(word, modelContext: modelContext)
                }
            }
            
            word.notes = notes
            word.isFavorite = isFavorite
            word.isConfident = isConfident
            word.collectionNames = Array(selectedCollectionNames)
            try? modelContext.save()
            return true
            
        case .editPhrase(let phrase):
            if itemText != phrase.phraseText {
                phrase.phraseText = itemText
                // Update fun opinion in background
                Task {
                    await PhraseService.shared.populatePhraseContent(phrase, modelContext: modelContext)
                }
            }
            
            phrase.notes = notes
            phrase.isFavorite = isFavorite
            phrase.collectionNames = Array(selectedCollectionNames)
            try? modelContext.save()
            return true
        }
    }
}
