import Foundation
import SwiftData

class WordService {
    static let shared = WordService()
    
    private init() {}
    
    @MainActor // Ensure this runs on the main actor
    // Changed: No longer returns Word, just creates it. Saving/population handled by saveWord.
    func createWord(text: String, notes: String = "", isFavorite: Bool = false, 
                    isConfident: Bool = false, collectionNames: [String] = []) async -> Word? { // Return Optional Word? or handle creation differently if needed
        print("WordService: Creating word with text: \(text)")
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Word initializer might be async due to SwiftData, so await is needed
        let word = await Word(wordText: trimmedText) 
        word.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        word.isFavorite = isFavorite
        word.isConfident = isConfident
        word.collectionNames = collectionNames
        
        // Instead of returning, perhaps just return the created object for the caller to pass to saveWord
        // Or modify saveWord to accept parameters instead of a Word object if creation needs separation
        // For now, returning the created word instance for the caller to handle.
        // The non-sendable error might persist if the caller is not MainActor.
        return word 
        // Consider alternative: Have createWord insert into context and return ID?
        // Or have saveWord accept parameters? This seems complex. Let's stick with returning Word for now.
    }
    
    @MainActor // Ensure this runs on the main actor
    func populateWordContent(_ word: Word, modelContext: ModelContext? = nil) async {
        print("WordService: Populating content for word: \(word.wordText)")
        
        // Fetch data asynchronously (can happen off main actor)
        var fetchedMeanings: [Word.WordMeaning] = []
        var fetchedAudioURL: String? = nil
        var fetchedFunFact: String = ""
        
        print("WordService: Fetching dictionary definition for: \(word.wordText)")
        if let entry = try? await DictionaryService.shared.fetchDefinition(for: word.wordText) {
            print("WordService: Successfully fetched definition with \(entry.meanings.count) meanings")
            fetchedMeanings = entry.meanings.map { meaning in
                Word.WordMeaning(
                    partOfSpeech: meaning.partOfSpeech,
                    definition: meaning.definition,
                    example: meaning.example,
                    synonyms: meaning.synonyms,
                    antonyms: meaning.antonyms
                )
            }
            fetchedAudioURL = entry.audioURL
            print("WordService: Fetching fun fact for: \(word.wordText)")
            fetchedFunFact = await fetchFunFact(for: word.wordText) // Assuming this exists and returns String
            print("WordService: Successfully fetched fun fact")
        } else {
            print("WordService: Failed to fetch dictionary definition for: \(word.wordText)")
        }
        
        // Update the model (guaranteed to be on MainActor here)
        print("WordService: Updating word model with \(fetchedMeanings.count) meanings")
        word.meanings = fetchedMeanings
        word.audioURL = fetchedAudioURL
        word.funFact = fetchedFunFact
        
        // Save if context provided
        if let context = modelContext {
            print("WordService: Saving word to database")
            do {
                try context.save()
                print("WordService: Word saved successfully")
            } catch {
                print("WordService: Error saving word after populating content: \(error)")
            }
        } else {
            print("WordService: No context provided, skipping save")
        }
    }

    @MainActor // Ensure this runs on the main actor
    func refreshWordDetails(_ word: Word, modelContext: ModelContext? = nil) async {
        print("WordService: Refreshing details for word: \(word.wordText)")
        
        // Fetch data asynchronously
        var fetchedMeanings: [Word.WordMeaning] = []
        var fetchedAudioURL: String? = nil

        print("WordService: Fetching dictionary definition for refresh: \(word.wordText)")
        if let entry = try? await DictionaryService.shared.fetchDefinition(for: word.wordText) {
            print("WordService: Successfully fetched definition for refresh with \(entry.meanings.count) meanings")
            fetchedMeanings = entry.meanings.map { meaning in
                Word.WordMeaning(
                    partOfSpeech: meaning.partOfSpeech,
                    definition: meaning.definition,
                    example: meaning.example,
                    synonyms: meaning.synonyms,
                    antonyms: meaning.antonyms
                )
            }
            fetchedAudioURL = entry.audioURL
        } else {
            print("WordService: Failed to fetch dictionary definition for refresh: \(word.wordText)")
        }

        // Update the model (guaranteed to be on MainActor here)
        // Only update if the fetch was successful and returned meanings
        if !fetchedMeanings.isEmpty {
            print("WordService: Updating word model with refreshed details (\(fetchedMeanings.count) meanings)")
            word.meanings = fetchedMeanings
            word.audioURL = fetchedAudioURL // Update audio URL regardless of meanings, if fetched
        } else if fetchedAudioURL != nil {
             // If meanings fetch failed but audio was fetched (unlikely with current DictionaryService), update audio only
             print("WordService: Updating only audio URL as meanings fetch failed or returned empty.")
             word.audioURL = fetchedAudioURL
        } else {
            print("WordService: Skipping model update as fetch failed or returned no data.")
        }

        // Save if context provided (only save if changes were actually made, though saving harmlessly is okay too)
        if let context = modelContext {
            print("WordService: Saving refreshed word details to database")
            do {
                try context.save()
                print("WordService: Refreshed word details saved successfully")
            } catch {
                 print("WordService: Error saving word after refreshing details: \(error)")
            }
        } else {
            print("WordService: No context provided, skipping save after refresh")
        }
    }
    
    @MainActor
    func saveWord(_ word: Word, modelContext: ModelContext) { // No longer needs async
        print("WordService: Saving word: \(word.wordText) to database")
        Word.save(word, modelContext: modelContext) // Assuming Word.save is synchronous or MainActor-bound
        print("WordService: Word initially saved, launching task for content population")
        
        // Populate content using a Task that inherits the MainActor context
        Task {
            print("WordService: Task started for populating word content")
            // Pass modelContext explicitly if populateWordContent needs it
            // and if it's safe to do so (which it is since both are @MainActor)
            await self.populateWordContent(word, modelContext: modelContext)
            print("WordService: Task completed for populating word content")
        }
    }
}
