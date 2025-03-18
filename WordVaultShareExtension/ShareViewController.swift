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
            saveSharedText(text)
        }
        
        // Complete the extension
        print("Completing extension request")
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
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
        self.placeholder = "Add a note (optional)"
    }
    
    private func saveSharedText(_ text: String) {
        print("Attempting to save text: \(text)")

        let item = Item(itemText: text)
        let container = try! ModelContainer(for: Item.self)
        let context = container.mainContext
        Item.save(item, modelContext: context)
        print("Saved text as new Item: \(item.itemText)")
    }

}
