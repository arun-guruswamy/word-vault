//
//  ShareViewController.swift
//  WordVaultShareExtension
//
//  Created by CREO SYSTEMS on 3/18/25.
//

import UIKit
import Social
import UniformTypeIdentifiers
import SwiftData
import Foundation

// Import needed services and models from main app
class ShareViewController: SLComposeServiceViewController {
    // App group identifier for shared container
    private let appGroupIdentifier = "group.com.arun-guruswamy.WordVault"
    
    // Use the same container setup as the main app with shared storage URL
    private var modelContainer: ModelContainer? = nil
    
    override func isContentValid() -> Bool {
        // Any text is valid
        return true
    }

    override func didSelectPost() {
        print("Post button tapped")
        
        // Get the text from the text view
        if let text = contentText {
            print("Text from contentText: \(text)")
            
            // Use Task with a completion handler to ensure all async work is done
            Task {
                await saveSharedText(text)
                
                // Small delay to ensure data is fully saved
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                // Complete the extension after saving
                print("Completing extension request")
                await MainActor.run {
                    self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                }
            }
        } else {
            // Complete the extension if no text
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("View did load")
        
        // Set the title and placeholder text
        self.title = "Add to Word Vault"
        self.placeholder = "Add a word or phrase"
        
        // Change "Post" button to "Add"
        self.navigationItem.rightBarButtonItem?.title = "Add"
        
        // Initialize model container
        setupModelContainer()
    }
    
    private func setupModelContainer() {
        do {
            let schema = Schema([
                Word.self,
                Phrase.self,
                Collection.self
            ])
            
            // Create model configuration with shared storage
            let modelConfiguration = ModelConfiguration(
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .identifier(appGroupIdentifier)
            )
            
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("Successfully created model container with shared app group: \(appGroupIdentifier)")
        } catch {
            print("Could not create ModelContainer: \(error)")
        }
    }
    
    @MainActor
    private func saveSharedText(_ text: String) async {
        print("Attempting to save text: \(text)")

        do {
            guard let modelContainer = self.modelContainer else {
                print("Model container not initialized")
                return
            }
            
            let context = modelContainer.mainContext
            
            // Fetch existing words and phrases to check item count
            let existingWords = Word.fetchAll(modelContext: context)
            let existingPhrases = Phrase.fetchAll(modelContext: context)
            let totalItemCount = existingWords.count + existingPhrases.count
            
            if totalItemCount >= 50 {
                print("Item limit reached. Cannot save new item.")
                return // Skip saving if item limit is reached
            }
            
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for duplicates (case-insensitive)
            let isDuplicateWord = existingWords.contains { word in
                word.wordText.lowercased() == trimmedText.lowercased()
            }
            
            let isDuplicatePhrase = existingPhrases.contains { phrase in
                phrase.phraseText.lowercased() == trimmedText.lowercased()
            }
            
            if isDuplicateWord || isDuplicatePhrase {
                print("Duplicate item found: \(trimmedText)")
                // Handle duplicate (e.g., show an alert, skip saving)
                return // Skip saving if duplicate
            }
            
            // Determine if text is a word or phrase
            let isPhrase = trimmedText.split(separator: " ").count > 1
            
            if isPhrase {
                // Create and save a phrase using the service
                print("Creating phrase from text: \(trimmedText)")
                let phrase = PhraseService.shared.createPhrase(text: trimmedText)
                await PhraseService.shared.savePhrase(phrase, modelContext: context)
                print("Saved text as Phrase: \(phrase.phraseText)")
                
                // Manually populate phrase content to ensure it's completed
                await PhraseService.shared.populatePhraseContent(phrase, modelContext: context)
            } else {
                // Create and save a word using the service
                print("Creating word from text: \(trimmedText)")
                let word = await WordService.shared.createWord(text: trimmedText)
                await WordService.shared.saveWord(word, modelContext: context)
                print("Saved text as Word: \(word.wordText)")
                
                // Manually populate word content to ensure it's completed
                await WordService.shared.populateWordContent(word, modelContext: context)
                
                // Print confirmation with meanings count to verify data was saved
                if !word.meanings.isEmpty {
                    print("Word saved with \(word.meanings.count) meanings")
                } else {
                    print("Warning: Word meanings may be empty - dictionary fetch in progress")
                }
            }
            
            // Final save to ensure all changes are persisted
            try context.save()
            print("Final context save completed")
            
        } catch {
            print("Error saving shared text: \(error)")
        }
    }
}
