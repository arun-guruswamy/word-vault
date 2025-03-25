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
            
        case .editWord(let word):
            self.existingWord = word
            self.existingPhrase = nil
            _itemText = State(initialValue: word.wordText)
            _notes = State(initialValue: word.notes)
            _selectedCollectionNames = State(initialValue: Set(word.collectionNames))
            _isFavorite = State(initialValue: word.isFavorite)
            
        case .editPhrase(let phrase):
            self.existingWord = nil
            self.existingPhrase = phrase
            _itemText = State(initialValue: phrase.phraseText)
            _notes = State(initialValue: phrase.notes)
            _selectedCollectionNames = State(initialValue: Set(phrase.collectionNames))
            _isFavorite = State(initialValue: phrase.isFavorite)
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
        NavigationView {
            Form {
                Section(header: Text("Text")) {
                    TextField("Enter word or phrase", text: $itemText)
                }
                
                Section(header: Text("Collections")) {
                    Button(action: {
                        isFavorite.toggle()
                    }) {
                        HStack {
                            Text("Favorites")
                                .foregroundColor(.primary)
                            Spacer()
                            if isFavorite {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
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
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedCollectionNames.contains(collection.name) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Notes"), footer: Text("Add any personal notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        Task {
                            let success = await saveItem()
                            if success {
                                dismiss()
                            }
                        }
                    }
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
            return word.wordText.lowercased() == itemText.lowercased()
        }
        
        let isDuplicatePhrase = existingPhrases.contains { phrase in
            // Skip the current phrase if we're editing it
            if case .editPhrase(let currentPhrase) = mode, phrase.id == currentPhrase.id {
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
                let newPhrase = Phrase(phraseText: itemText)
                newPhrase.notes = notes
                newPhrase.isFavorite = isFavorite
                newPhrase.collectionNames = Array(selectedCollectionNames)
                Phrase.save(newPhrase, modelContext: modelContext)
                Task {
                    newPhrase.funOpinion = await fetchFunOpinion(for: newPhrase.phraseText)
                    try? modelContext.save()
                }
                return true
            } else {
                // Create word with empty definition first
                let newWord = await Word(wordText: itemText)
                newWord.notes = notes
                newWord.isFavorite = isFavorite
                newWord.collectionNames = Array(selectedCollectionNames)
                Word.save(newWord, modelContext: modelContext)
                
                // Fetch definition and fun fact in the background
                Task {
                    if let entry = try? await DictionaryService.shared.fetchDefinition(for: itemText) {
                        newWord.definition = entry.meanings.first?.definitions.first?.definition ?? "No definition found"
                        newWord.example = entry.meanings.first?.definitions.first?.example ?? "No example available"
                        newWord.meanings = entry.meanings.map { meaning in
                            Word.WordMeaning(
                                partOfSpeech: meaning.partOfSpeech,
                                definitions: meaning.definitions.map { def in
                                    Word.WordDefinition(
                                        definition: def.definition,
                                        example: def.example
                                    )
                                }
                            )
                        }
                        newWord.audioURL = entry.audioURL
                        newWord.funFact = await fetchFunFact(for: newWord.wordText)
                    }
                    
                    try? modelContext.save()
                }
                return true
            }
            
        case .editWord(let word):
            if itemText != word.wordText {
                // Update word text first
                word.wordText = itemText
                word.definition = "Loading definition..."
                word.example = "Loading example..."
                word.meanings = []
                word.audioURL = nil
                try? modelContext.save()
                
                // Fetch new definition in the background
                Task {
                    if let entry = try? await DictionaryService.shared.fetchDefinition(for: itemText) {
                        word.definition = entry.meanings.first?.definitions.first?.definition ?? "No definition found"
                        word.example = entry.meanings.first?.definitions.first?.example ?? "No example available"
                        word.meanings = entry.meanings.map { meaning in
                            Word.WordMeaning(
                                partOfSpeech: meaning.partOfSpeech,
                                definitions: meaning.definitions.map { def in
                                    Word.WordDefinition(
                                        definition: def.definition,
                                        example: def.example
                                    )
                                }
                            )
                        }
                        word.audioURL = entry.audioURL
                        word.funFact = await fetchFunFact(for: word.wordText)
                        
                    } else {
                        word.meanings = []
                        word.audioURL = nil
                    }

                    try? modelContext.save()
                }
            }
            word.notes = notes
            word.isFavorite = isFavorite
            word.collectionNames = Array(selectedCollectionNames)
            try? modelContext.save()
            return true
            
        case .editPhrase(let phrase):
            phrase.phraseText = itemText
            phrase.notes = notes
            phrase.isFavorite = isFavorite
            phrase.collectionNames = Array(selectedCollectionNames)
            try? modelContext.save()
            return true
        }
    }
} 
