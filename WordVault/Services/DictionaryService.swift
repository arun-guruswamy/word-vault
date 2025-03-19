import Foundation

// MARK: - Dictionary Service
public class DictionaryService {
    public static let shared = DictionaryService()
    
    init() {}
    
    public func fetchDefinition(for word: String) async throws -> DictionaryEntry? {
        let urlString = "https://api.dictionaryapi.dev/api/v2/entries/en/\(word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? word)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        let definitions = try decoder.decode([DictionaryEntry].self, from: data)
        
        return definitions.first
    }
}

// MARK: - Dictionary API Models
public struct DictionaryEntry: Codable {
    public let word: String
    public let meanings: [Meaning]
    
    public init(word: String, meanings: [Meaning]) {
        self.word = word
        self.meanings = meanings
    }
}

public struct Meaning: Codable {
    public let partOfSpeech: String
    public let definitions: [Definition]
    
    public init(partOfSpeech: String, definitions: [Definition]) {
        self.partOfSpeech = partOfSpeech
        self.definitions = definitions
    }
    
    enum CodingKeys: String, CodingKey {
        case partOfSpeech = "partOfSpeech"
        case definitions
    }
}

public struct Definition: Codable {
    public let definition: String
    public let example: String?
    
    public init(definition: String, example: String?) {
        self.definition = definition
        self.example = example
    }
} 