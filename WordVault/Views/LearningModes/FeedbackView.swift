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
                    .font(.custom("Marker Felt", size: 18))
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
                RoundedRectangle(cornerRadius: 3)
                    .fill(category.color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(Color.black, lineWidth: 2)
                    )
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Description banner
                        Text(category.description)
                            .font(.custom("BradleyHandITCTT-Bold", size: 14))
                            .fontWeight(.bold)
                            .italic()
                            .padding(10)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(category.color)
                            )
                        
                        // Evaluation content
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Detailed Feedback:")
                                .font(.custom("Marker Felt", size: 16))
                                .foregroundColor(category.color)
                            
                            Markdown(evaluation)
                                .font(.custom("BradleyHandITCTT-Bold", size: 14))
                                .foregroundColor(.black)
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
