import Foundation

// MARK: - Dictionary Service
public class DictionaryService {
    public static let shared = DictionaryService()
    private let baseURL = "https://api.dictionaryapi.dev/api/v2/entries/en"
    
    private init() {}
    
    public func fetchDefinition(for word: String) async throws -> DictionaryEntry {
        let urlString = "\(baseURL)/\(word.lowercased())"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let entries = try JSONDecoder().decode([APIResponse].self, from: data)
        
        guard let firstEntry = entries.first else {
            throw NSError(domain: "DictionaryService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No definition found"])
        }
        
        return DictionaryEntry(
            meanings: firstEntry.meanings.map { meaning in
                DictionaryEntry.Meaning(
                    partOfSpeech: meaning.partOfSpeech,
                    definitions: meaning.definitions.map { def in
                        DictionaryEntry.Definition(
                            definition: def.definition,
                            example: def.example
                        )
                    }
                )
            },
            audioURL: firstEntry.phonetics.first?.audio
        )
    }
    
    public func fetchAudio(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}

// MARK: - Dictionary API Models
public struct DictionaryEntry {
    public var meanings: [Meaning]
    public var audioURL: String?
    
    public struct Meaning {
        public var partOfSpeech: String
        public var definitions: [Definition]
    }
    
    public struct Definition {
        public var definition: String
        public var example: String?
    }
}

// MARK: - API Response Types
private struct APIResponse: Codable {
    var meanings: [APIMeaning]
    var phonetics: [APIPhonetic]
}

private struct APIMeaning: Codable {
    var partOfSpeech: String
    var definitions: [APIDefinition]
}

private struct APIDefinition: Codable {
    var definition: String
    var example: String?
}

private struct APIPhonetic: Codable {
    var audio: String?
} 