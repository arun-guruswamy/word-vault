import SwiftUI
import SwiftData
import Foundation

@Model
final class Word {
    var id: UUID
    var wordText: String
    var definition: String
    var example: String
    var notes: String
    var meanings: [WordMeaning]
    var createdAt: Date
    var collectionNames: [String]
    var isFavorite: Bool
    
    struct WordMeaning: Codable {
        var partOfSpeech: String
        var definitions: [WordDefinition]
    }
    
    struct WordDefinition: Codable {
        var definition: String
        var example: String?
    }
    
    init(wordText: String, skipDefinition: Bool = false) async {
        // Initialize all properties first
        self.id = UUID()
        self.wordText = wordText
        self.definition = skipDefinition ? "" : "Loading definition..."
        self.example = skipDefinition ? "" : "Loading example..."
        self.notes = ""
        self.meanings = []
        self.createdAt = Date()
        self.collectionNames = []
        self.isFavorite = false
        
        // Then fetch and update with API data if not skipping
        if !skipDefinition {
            if let entry = try? await DictionaryService.shared.fetchDefinition(for: wordText) {
                self.definition = entry.meanings.first?.definitions.first?.definition ?? "No definition found"
                self.example = entry.meanings.first?.definitions.first?.example ?? "No example available"
                
                // Store all meanings
                self.meanings = entry.meanings.map { meaning in
                    WordMeaning(
                        partOfSpeech: meaning.partOfSpeech,
                        definitions: meaning.definitions.map { def in
                            WordDefinition(
                                definition: def.definition,
                                example: def.example
                            )
                        }
                    )
                }
            }
        }
    }
}

// MARK: - SwiftData Operations
extension Word {
    static func save(_ word: Word, modelContext: ModelContext) {
        modelContext.insert(word)
        try? modelContext.save()
    }
    
    static func delete(_ word: Word, modelContext: ModelContext) {
        modelContext.delete(word)
        try? modelContext.save()
    }
    
    static func fetchAll(modelContext: ModelContext, sortBy: SortOption = .dateAdded(ascending: false)) -> [Word] {
        let descriptor = FetchDescriptor<Word>(
            sortBy: [sortBy.wordDescriptor]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    static func search(query: String, modelContext: ModelContext, sortBy: SortOption = .dateAdded(ascending: false)) -> [Word] {
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate<Word> { word in
                word.wordText.localizedStandardContains(query)
            },
            sortBy: [sortBy.wordDescriptor]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    static func fetchWordsInCollection(collectionName: String, modelContext: ModelContext, sortBy: SortOption = .dateAdded(ascending: false)) -> [Word] {
        // First fetch all words
        let allWords = fetchAll(modelContext: modelContext, sortBy: sortBy)
        
        // Filter words that belong to the collection
        let wordsInCollection = allWords.filter { word in
            return word.collectionNames.contains(collectionName)
        }
        
        return wordsInCollection
    }
} 
