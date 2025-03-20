import SwiftUI
import SwiftData
import Foundation

@Model
final class Collection {
    var id: UUID
    var name: String
    var createdAt: Date
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}

// MARK: - SwiftData Operations
extension Collection {
    static func save(_ collection: Collection, modelContext: ModelContext) {
        do {
            modelContext.insert(collection)
            try modelContext.save()
        } catch {
            print("Error saving collection: \(error)")
            modelContext.rollback()
        }
    }
    
    static func delete(_ collection: Collection, modelContext: ModelContext) {
        do {
            modelContext.delete(collection)
            try modelContext.save()
        } catch {
            print("Error deleting collection: \(error)")
            modelContext.rollback()
        }
    }
    
    static func fetchAll(modelContext: ModelContext) -> [Collection] {
        let descriptor = FetchDescriptor<Collection>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching collections: \(error)")
            return []
        }
    }
}
