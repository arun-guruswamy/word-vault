import Foundation
import SwiftData

class WordService {
    static let shared = WordService()
    
    private init() {}
    
    func createWord(text: String, notes: String = "", isFavorite: Bool = false, 
                   isConfident: Bool = false, collectionNames: [String] = []) async -> Word {
        print("WordService: Creating word with text: \(text)")
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let word = await Word(wordText: trimmedText)
        word.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        word.isFavorite = isFavorite
        word.isConfident = isConfident
        word.collectionNames = collectionNames
        
        return word
    }
    
    func populateWordContent(_ word: Word, modelContext: ModelContext? = nil) async {
        print("WordService: Populating content for word: \(word.wordText)")
        do {
            // First, fetch all the content asynchronously
            var meanings: [Word.WordMeaning] = []
            var audioURL: String? = nil
            var funFact: String = ""
            
            print("WordService: Fetching dictionary definition for: \(word.wordText)")
            if let entry = try? await DictionaryService.shared.fetchDefinition(for: word.wordText) {
                print("WordService: Successfully fetched definition with \(entry.meanings.count) meanings")
                meanings = entry.meanings.map { meaning in
                    Word.WordMeaning(
                        partOfSpeech: meaning.partOfSpeech,
                        definition: meaning.definition,
                        example: meaning.example,
                        synonyms: meaning.synonyms,
                        antonyms: meaning.antonyms
                    )
                }
                audioURL = entry.audioURL
                print("WordService: Fetching fun fact for: \(word.wordText)")
                funFact = await fetchFunFact(for: word.wordText)
                print("WordService: Successfully fetched fun fact")
            } else {
                print("WordService: Failed to fetch dictionary definition for: \(word.wordText)")
            }
            
            // Then update the model on the main thread
            await MainActor.run {
                print("WordService: Updating word model with \(meanings.count) meanings")
                word.meanings = meanings
                word.audioURL = audioURL
                word.funFact = funFact
                
                // Save if context provided
                if let context = modelContext {
                    print("WordService: Saving word to database")
                    try? context.save()
                    print("WordService: Word saved successfully")
                } else {
                    print("WordService: No context provided, skipping save")
                }
            }
        } catch {
            print("WordService: Error populating word content: \(error)")
        }
    }
    
    @MainActor
    func saveWord(_ word: Word, modelContext: ModelContext) async {
        print("WordService: Saving word: \(word.wordText) to database")
        Word.save(word, modelContext: modelContext)
        print("WordService: Word initially saved, launching background task for content population")
        
        // Populate content in background
        Task.detached {
            print("WordService: Background task started for populating word content")
            await self.populateWordContent(word, modelContext: modelContext)
            print("WordService: Background task completed")
        }
    }
} 
