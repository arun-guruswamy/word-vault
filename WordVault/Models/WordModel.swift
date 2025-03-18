import SwiftUI
import SwiftData
import Foundation

// MARK: - Dictionary Service
class DictionaryService {
    static let shared = DictionaryService()
    
    private init() {}
    
    func fetchDefinition(for word: String) async throws -> String {
        let urlString = "https://api.dictionaryapi.dev/api/v2/entries/en/\(word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? word)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        let definitions = try decoder.decode([DictionaryEntry].self, from: data)
        
        // Get the first definition from the first entry
        if let firstDefinition = definitions.first?.meanings.first?.definitions.first?.definition {
            return firstDefinition
        }
        
        return "No definition found"
    }
}

// MARK: - Dictionary API Models
struct DictionaryEntry: Codable {
    let word: String
    let meanings: [Meaning]
}

struct Meaning: Codable {
    let partOfSpeech: String
    let definitions: [Definition]
    
    enum CodingKeys: String, CodingKey {
        case partOfSpeech = "partOfSpeech"
        case definitions
    }
}

struct Definition: Codable {
    let definition: String
    let example: String?
}

@Model
final class Word {
    var id: UUID
    var wordText: String
    var definition: String
    var example: String
    var createdAt: Date
    
    init(wordText: String) async {
        self.id = UUID()
        self.wordText = wordText
        self.definition = (try? await DictionaryService.shared.fetchDefinition(for: wordText)) ?? "No definition found"
        self.example = "example test"
        self.createdAt = Date()
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
    
    static func fetchAll(modelContext: ModelContext) -> [Word] {
        let descriptor = FetchDescriptor<Word>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    static func search(query: String, modelContext: ModelContext) -> [Word] {
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate<Word> { word in
                word.wordText.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
} 