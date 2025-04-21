import SwiftUI
import SwiftData
import Foundation

@Model
final class Word {
    var id: UUID = UUID()
    var wordText: String = ""
    var notes: String = ""
    var meanings: [WordMeaning] = []
    var createdAt: Date = Date()
    var collectionNames: [String] = []
    var isFavorite: Bool = false
    var isConfident: Bool = false
    var funFact: String = ""
    var audioURL: String? // Already optional
    var linkedItemIDs: [UUID] = [] // Added for linking
    
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
    
    // Initializer can be simplified or removed if only default values are needed upon creation
    // Keeping it for now in case specific wordText initialization is still desired elsewhere
    // Keeping async and @MainActor as they were present before, though potentially unnecessary now
    @MainActor 
    init(wordText: String = "") async { // Provide default for wordText parameter too
        self.wordText = wordText
        // Other properties are already initialized with defaults
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
