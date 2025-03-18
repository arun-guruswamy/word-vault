import SwiftUI
import SwiftData

@Model
final class Item {
    var id: UUID
    var itemText: String
    var definition: String
    var example: String
    var createdAt: Date
    
    init(itemText: String) {
        self.id = UUID()
        self.itemText = itemText
        self.definition = "definition test"
        self.example = "example test"
        self.createdAt = Date()
    }
}

// MARK: - SwiftData Operations
extension Item {
    static func save(_ item: Item, modelContext: ModelContext) {
        modelContext.insert(item)
        try? modelContext.save()
    }
    
    static func delete(_ item: Item, modelContext: ModelContext) {
        modelContext.delete(item)
        try? modelContext.save()
    }
    
    static func fetchAll(modelContext: ModelContext) -> [Item] {
        let descriptor = FetchDescriptor<Item>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    static func search(query: String, modelContext: ModelContext) -> [Item] {
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate<Item> { item in
                item.itemText.localizedStandardContains(query) ||
                item.definition.localizedStandardContains(query) ||
                item.example.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
} 