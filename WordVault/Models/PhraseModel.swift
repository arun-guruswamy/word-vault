import SwiftUI
import SwiftData
import Foundation

@Model
final class Phrase {
    var id: UUID
    var phraseText: String
    var notes: String
    var createdAt: Date
    var collectionNames: [String]
    var isFavorite: Bool
    
    init(phraseText: String) {
        self.id = UUID()
        self.phraseText = phraseText
        self.notes = ""
        self.createdAt = Date()
        self.collectionNames = []
        self.isFavorite = false
    }
}

// MARK: - SwiftData Operations
extension Phrase {
    static func save(_ phrase: Phrase, modelContext: ModelContext) {
        modelContext.insert(phrase)
        try? modelContext.save()
    }
    
    static func delete(_ phrase: Phrase, modelContext: ModelContext) {
        modelContext.delete(phrase)
        try? modelContext.save()
    }
    
    static func fetchAll(modelContext: ModelContext, sortBy: SortOption = .dateAdded(ascending: false)) -> [Phrase] {
        let descriptor = FetchDescriptor<Phrase>(
            sortBy: [sortBy.phraseDescriptor]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    static func search(query: String, modelContext: ModelContext, sortBy: SortOption = .dateAdded(ascending: false)) -> [Phrase] {
        let descriptor = FetchDescriptor<Phrase>(
            predicate: #Predicate<Phrase> { phrase in
                phrase.phraseText.localizedStandardContains(query)
            },
            sortBy: [sortBy.phraseDescriptor]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    static func fetchPhrasesInCollection(collectionName: String, modelContext: ModelContext, sortBy: SortOption = .dateAdded(ascending: false)) -> [Phrase] {
        // First fetch all phrases
        let allPhrases = fetchAll(modelContext: modelContext, sortBy: sortBy)
        
        // Filter phrases that belong to the collection
        let phrasesInCollection = allPhrases.filter { phrase in
            return phrase.collectionNames.contains(collectionName)
        }
        
        return phrasesInCollection
    }
} 
