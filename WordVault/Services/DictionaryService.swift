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
        
        // Process API response and generate examples where needed
        var meanings: [DictionaryEntry.Meaning] = []
        
        for meaning in firstEntry.meanings {
            for def in meaning.definitions {
                let example: String?
                
                // Generate an example if one is not provided by the API
                if let apiExample = def.example, !apiExample.isEmpty {
                    example = apiExample
                } else {
                    // Generate example using LLM
                    example = await generateExample(
                        for: word,
                        partOfSpeech: meaning.partOfSpeech,
                        definition: def.definition
                    )
                }
                
                meanings.append(DictionaryEntry.Meaning(
                    partOfSpeech: meaning.partOfSpeech,
                    definition: def.definition,
                    example: example,
                    synonyms: def.synonyms ?? [],
                    antonyms: def.antonyms ?? []
                ))
            }
        }
        
        return DictionaryEntry(
            meanings: meanings,
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
    
    public func generateExample(for word: String, partOfSpeech: String, definition: String) async -> String {
        do {
            let message = """
            Create a natural and conversational example sentence that illustrates the usage of the word "\(word)" 
            as a \(partOfSpeech) with this definition: "\(definition)".
            
            Guidelines:
            - Use contemporary, everyday language that feels natural
            - Create a sentence that clearly demonstrates the meaning
            - Be sure to use "\(word)" in the sentence
            - Keep it concise (ideally 10-15 words)
            - Make it memorable and relatable
            - Respond with ONLY the example sentence and nothing else
            - If you cant think of example, just state Could not come up with an example
            
            Example sentence:
            """
            let response = try await chat.sendMessage(message)
            let example = response.text ?? "No example available"
            
            // Clean up the response (remove quotes if they exist)
            return example.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "^\"(.*)\"$", with: "$1", options: .regularExpression)
        } catch {
            print(error)
            return "No example available"
        }
    }
}

// MARK: - Dictionary API Models
public struct DictionaryEntry {
    public var meanings: [Meaning]
    public var audioURL: String?
    
    public struct Meaning {
        public var partOfSpeech: String
        public var definition: String
        public var example: String?
        public var synonyms: [String]
        public var antonyms: [String]
        
        public init(partOfSpeech: String, definition: String, example: String? = nil, synonyms: [String] = [], antonyms: [String] = []) {
            self.partOfSpeech = partOfSpeech
            self.definition = definition
            self.example = example
            self.synonyms = synonyms
            self.antonyms = antonyms
        }
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
    var synonyms: [String]?
    var antonyms: [String]?
}

private struct APIDefinition: Codable {
    var definition: String
    var example: String?
    var synonyms: [String]?
    var antonyms: [String]?
}

private struct APIPhonetic: Codable {
    var audio: String?
} 
