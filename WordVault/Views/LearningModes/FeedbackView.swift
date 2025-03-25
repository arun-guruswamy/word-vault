import SwiftUI
import MarkdownUI

// MARK: - Feedback View
struct FeedbackView: View {
    let category: FeedbackCategory
    let evaluation: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category header with badge
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(8)
                    .background(Circle().fill(category.color))
                
                Text(category.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(category.color)
                
                Spacer()
                
                // Star rating display - showing the correct number of stars for each category
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < category.stars ? "star.fill" : "star")
                            .foregroundColor(category.color)
                    }
                }
            }
            .padding(.horizontal)
            
            // Feedback content
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(category.color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(category.color, lineWidth: 2)
                    )
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Description banner
                        Text(category.description)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .italic()
                            .padding(10)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(category.color)
                            )
                        
                        // Feedback guidelines
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Feedback Guidelines:")
                                .font(.headline)
                                .foregroundColor(category.color)
                            
                            Text(category.feedbackGuidelines)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(uiColor: .systemGray6))
                                )
                        }
                        
                        // Evaluation content
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Detailed Feedback:")
                                .font(.headline)
                                .foregroundColor(category.color)
                            
                            Markdown(evaluation)
                                .font(.body)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.35)
        }
    }
}
