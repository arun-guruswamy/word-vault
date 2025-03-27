import SwiftUI

enum FeedbackCategory: String {
    case exceptional = "Exceptional"
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case needsImprovement = "Needs Improvement"
    
    var icon: String {
        switch self {
        case .exceptional: return "star.circle.fill"
        case .excellent: return "star.fill"
        case .good: return "checkmark.circle.fill"
        case .fair: return "exclamationmark.circle.fill"
        case .needsImprovement: return "arrow.up.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .exceptional: return .purple
        case .excellent: return .blue
        case .good: return .green
        case .fair: return .orange
        case .needsImprovement: return .red
        }
    }
    
    var description: String {
        switch self {
        case .exceptional:
            return "Outstanding work! Your response demonstrates exceptional understanding and creativity."
        case .excellent:
            return "Excellent job! You've shown strong comprehension and thoughtful application."
        case .good:
            return "Good effort! Your understanding is solid with some room for refinement."
        case .fair:
            return "Fair attempt. Let's work on strengthening your understanding."
        case .needsImprovement:
            return "Keep practicing! Focus on understanding the core concept better."
        }
    }
    
    var stars: Int {
        switch self {
        case .exceptional: return 5
        case .excellent: return 4
        case .good: return 3
        case .fair: return 2
        case .needsImprovement: return 1
        }
    }
}

enum LearningMode: String, CaseIterable {
    case wordDefinitionWriting = "Definition Writing"
    case wordUsage = "Word Usage"
    
    var description: String {
        switch self {
        case .wordDefinitionWriting:
            return "Write definitions for words to test your understanding"
        case .wordUsage:
            return "Create sentences using words to practice their usage"
        }
    }
    
    var icon: String {
        switch self {
        case .wordDefinitionWriting:
            return "text.book.closed.fill"
        case .wordUsage:
            return "text.bubble.fill"
        }
    }
} 
