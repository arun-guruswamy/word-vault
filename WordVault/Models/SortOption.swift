import SwiftUI
import SwiftData

enum SortOption: Hashable {
    case dateAdded(ascending: Bool)
    case alphabetically(ascending: Bool)
    
    var wordDescriptor: SortDescriptor<Word> {
        switch self {
        case .dateAdded(let ascending):
            return SortDescriptor(\Word.createdAt, order: ascending ? .forward : .reverse)
        case .alphabetically(let ascending):
            return SortDescriptor(\Word.wordText, order: ascending ? .forward : .reverse)
        }
    }
    
    var phraseDescriptor: SortDescriptor<Phrase> {
        switch self {
        case .dateAdded(let ascending):
            return SortDescriptor(\Phrase.createdAt, order: ascending ? .forward : .reverse)
        case .alphabetically(let ascending):
            return SortDescriptor(\Phrase.phraseText, order: ascending ? .forward : .reverse)
        }
    }
} 