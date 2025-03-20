import SwiftUI
import SwiftData

struct WordFormView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var collections: [Collection]
    
    // State variables
    @State private var wordText: String
    @State private var notes: String
    @State private var selectedCollectionNames: Set<String>
    @State private var isFavorite: Bool
    
    // Mode and existing word (if editing)
    private let mode: Mode
    private let existingWord: Word?
    
    enum Mode {
        case add
        case edit
    }
    
    init(mode: Mode, word: Word? = nil) {
        self.mode = mode
        self.existingWord = word
        
        // Initialize state variables
        _wordText = State(initialValue: word?.wordText ?? "")
        _notes = State(initialValue: word?.notes ?? "")
        _selectedCollectionNames = State(initialValue: Set(word?.collectionNames ?? []))
        _isFavorite = State(initialValue: word?.isFavorite ?? false)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Word")) {
                    TextField("Word or phrase", text: $wordText)
                }
                
                Section(header: Text("Collections")) {
                    Button(action: {
                        isFavorite.toggle()
                    }) {
                        HStack {
                            Text("Favorites")
                                .foregroundColor(.black)
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
                                    .foregroundColor(.black)
                                Spacer()
                                if selectedCollectionNames.contains(collection.name) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Notes"), footer: Text("Add any personal notes about this word")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(mode == .add ? "Add New Word" : "Edit Word")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    Task {
                        if mode == .add {
                            // Create new word
                            let newWord = await Word(wordText: wordText)
                            newWord.notes = notes
                            newWord.isFavorite = isFavorite
                            newWord.collectionNames = Array(selectedCollectionNames)
                            Word.save(newWord, modelContext: modelContext)
                        } else if let word = existingWord {
                            // Update existing word
                            if wordText != word.wordText {
                                // Update word text and try to fetch new definitions
                                if let entry = try? await DictionaryService.shared.fetchDefinition(for: wordText) {
                                    // If word exists in dictionary, update with new data
                                    word.wordText = wordText
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
                                } else {
                                    // If word doesn't exist in dictionary, update word text and clear dictionary data
                                    word.wordText = wordText
                                    word.definition = "No definition found"
                                    word.example = "No example available"
                                    word.meanings = []
                                }
                            }
                            word.notes = notes
                            word.isFavorite = isFavorite
                            word.collectionNames = Array(selectedCollectionNames)
                            try? modelContext.save()
                        }
                        dismiss()
                    }
                }
                .disabled(wordText.isEmpty)
            )
        }
    }
} 
