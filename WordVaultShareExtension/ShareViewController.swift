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

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        print("Checking content validity")
        return true
    }

    override func didSelectPost() {
        print("Post button tapped")
        
        // Get the text from the text view
        if let text = contentText {
            print("Text from contentText: \(text)")
            Task {
                await saveSharedText(text)
                // Complete the extension after saving
                print("Completing extension request")
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
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
    }
    
    private func saveSharedText(_ text: String) async {
        print("Attempting to save text: \(text)")

        do {
            let word = await Word(wordText: text)
            let container = try ModelContainer(for: Word.self)
            let context = container.mainContext
            Word.save(word, modelContext: context)
            print("Saved text as new Item: \(word.wordText)")
        } catch {
            print("Error saving word: \(error)")
        }
    }

    // Override the localized string for the post button
    func textForPublishButton() -> String {
        return "Add"
    }

}
