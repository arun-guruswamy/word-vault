import SwiftUI
import SwiftData
import Charts

// Struct to hold data for the confidence chart
struct ConfidenceStat: Identifiable {
    let id = UUID()
    let category: String // "Confident" or "Learning"
    let count: Int
}

// Struct to hold data for the word length chart
struct WordLengthStat: Identifiable {
    let id = UUID()
    let lengthCategory: String // e.g., "1-3", "4-6", "7-9", "10+"
    let count: Int
}

@Observable
class StatsViewModel {
    private var modelContext: ModelContext
    
    var words: [Word] = []
    var phrases: [Phrase] = []
    
    var totalWordCount: Int = 0
    var totalPhraseCount: Int = 0
    
    var wordConfidenceStats: [ConfidenceStat] = []
    var wordLengthStats: [WordLengthStat] = [] // New property for word length stats

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchData()
    }

    func fetchData() {
        // Fetch all words and phrases
        self.words = Word.fetchAll(modelContext: modelContext)
        self.phrases = Phrase.fetchAll(modelContext: modelContext)
        
        // Calculate initial stats
        calculateTotalCounts()
        calculateWordConfidence()
        calculateWordLengthDistribution() // Calculate word length stats
    }

    private func calculateTotalCounts() {
        totalWordCount = words.count
        totalPhraseCount = phrases.count
    }

    private func calculateWordConfidence() {
        let confidentCount = words.filter { $0.isConfident }.count
        let learningCount = words.count - confidentCount
        
        wordConfidenceStats = [
            ConfidenceStat(category: "Confident", count: confidentCount),
            ConfidenceStat(category: "Learning", count: learningCount)
        ].filter { $0.count > 0 } // Only include categories with counts > 0
    }

    private func calculateWordLengthDistribution() {
        var counts: [String: Int] = [
            "1-3": 0,
            "4-6": 0,
            "7-9": 0,
            "10+": 0
        ]

        for word in words {
            let length = word.wordText.count
            switch length {
            case 1...3:
                counts["1-3", default: 0] += 1
            case 4...6:
                counts["4-6", default: 0] += 1
            case 7...9:
                counts["7-9", default: 0] += 1
            default: // 10 or more
                counts["10+", default: 0] += 1
            }
        }

        // Convert dictionary to array of WordLengthStat, filtering out empty categories
        wordLengthStats = counts.map { category, count in
            WordLengthStat(lengthCategory: category, count: count)
        }
        .filter { $0.count > 0 }
        // Optional: Sort categories for consistent order in the chart legend
        .sorted { // Sort numerically based on the start of the range
            let range1 = $0.lengthCategory.split(separator: "-").first?.trimmingCharacters(in: .punctuationCharacters) ?? "0"
            let range2 = $1.lengthCategory.split(separator: "-").first?.trimmingCharacters(in: .punctuationCharacters) ?? "0"
            return Int(range1) ?? 0 < Int(range2) ?? 0
        }
    }
}
