import Foundation
import SwiftData

class SharedTextService {
    static let shared = SharedTextService()
    
    private let sharedDefaults = UserDefaults(suiteName: "group.com.yourdomain.wordvault")
    
    func getSharedTexts() -> [String] {
        return sharedDefaults?.array(forKey: "SharedTexts") as? [String] ?? []
    }
    
    func clearSharedTexts() {
        sharedDefaults?.removeObject(forKey: "SharedTexts")
        sharedDefaults?.synchronize()
    }
    
    func saveToItems(texts: [String], modelContext: ModelContext) {
        for text in texts {
            let newItem = Item(itemText: text)
            Item.save(newItem, modelContext: modelContext)
        }
        clearSharedTexts()
    }
} 