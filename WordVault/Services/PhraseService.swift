import Foundation
import SwiftData

class PhraseService {
    static let shared = PhraseService()
    
    private init() {}
    
    func createPhrase(text: String, notes: String = "", isFavorite: Bool = false, 
                     collectionNames: [String] = []) -> Phrase {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let phrase = Phrase(phraseText: trimmedText)
        phrase.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        phrase.isFavorite = isFavorite
        phrase.collectionNames = collectionNames
        
        return phrase
    }
    
    func populatePhraseContent(_ phrase: Phrase, modelContext: ModelContext? = nil) async {
        // First, fetch the content asynchronously
        let funOpinion = await fetchFunOpinion(for: phrase.phraseText)
        
        // Then update the model on the main thread
        await MainActor.run {
            phrase.funOpinion = funOpinion
            
            // Save if context provided
            if let context = modelContext {
                try? context.save()
            }
        }
    }
    
    @MainActor
    func savePhrase(_ phrase: Phrase, modelContext: ModelContext) async {
        Phrase.save(phrase, modelContext: modelContext)
        
        // Populate content in background
        Task.detached {
            await self.populatePhraseContent(phrase, modelContext: modelContext)
        }
    }
} 