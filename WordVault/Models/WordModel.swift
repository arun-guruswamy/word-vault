import SwiftUI
import SwiftData
import Foundation

@Model
final class Word {
    var id: UUID
    var wordText: String
    var notes: String
    var meanings: [WordMeaning]
    var createdAt: Date
    var collectionNames: [String]
    var isFavorite: Bool
    var isConfident: Bool
    var funFact: String
    var audioURL: String?
    
    struct WordMeaning: Codable {
        var partOfSpeech: String
        var definition: String
        var example: String?
        var synonyms: [String]
        var antonyms: [String]
        
        init(partOfSpeech: String, definition: String, example: String? = nil, synonyms: [String] = [], antonyms: [String] = []) {
            self.partOfSpeech = partOfSpeech
            self.definition = definition
            self.example = example
            self.synonyms = synonyms
            self.antonyms = antonyms
        }
    }
    
    init(wordText: String) async {
        // Initialize all properties
        self.id = UUID()
        self.wordText = wordText
        self.notes = ""
        self.meanings = []
        self.createdAt = Date()
        self.collectionNames = []
        self.isFavorite = false
        self.isConfident = false
        self.funFact = ""
        self.audioURL = nil
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
    
    static func fetchConfidentWords(modelContext: ModelContext, sortBy: SortOption = .dateAdded(ascending: false)) -> [Word] {
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate<Word> { word in
                word.isConfident == true
            },
            sortBy: [sortBy.wordDescriptor]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
} 
