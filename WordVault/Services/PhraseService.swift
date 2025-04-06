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
    
    // Removed populatePhraseContent as its logic is integrated below

    @MainActor
    func savePhrase(_ phrase: Phrase, modelContext: ModelContext) { // No longer needs async
        // Save the initial phrase or update existing properties on the MainActor
        // Assuming Phrase.save handles insertion/initial save
        Phrase.save(phrase, modelContext: modelContext)
        
        // Launch a task on the MainActor to fetch and update the fun opinion
        Task {
            // Fetch opinion asynchronously (can switch threads internally)
            // Assuming fetchFunOpinion exists and returns String
            let funOpinion = await fetchFunOpinion(for: phrase.phraseText)
            
            // Update the phrase (still on MainActor)
            // Check if the phrase object is still valid in the context by fetching it
            let phraseID = phrase.id // Capture the ID locally
            let fetchDescriptor = FetchDescriptor<Phrase>(predicate: #Predicate { $0.id == phraseID })
            if let fetchedPhrase = try? modelContext.fetch(fetchDescriptor).first {
                 // Phrase exists in context, update it
                 fetchedPhrase.funOpinion = funOpinion
                 // Save the updated phrase context
                 do {
                     try modelContext.save()
                 } catch {
                     // Handle or log the save error appropriately
                     print("Error saving phrase after updating fun opinion: \(error)")
                 }
            } else {
                 print("Phrase \(phrase.id) no longer in context, skipping funOpinion update.")
            }
        }
    }
    
    // Assume fetchFunOpinion is defined elsewhere, e.g.:
    // func fetchFunOpinion(for text: String) async -> String { ... }
}
