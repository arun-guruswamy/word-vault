import SwiftUI
import SwiftData
import MarkdownUI

struct WordDefinitionWritingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Word.createdAt) private var words: [Word]
    @State private var currentWord: Word?
    @State private var userDefinition = ""
    @State private var isEvaluating = false
    @State private var evaluationResult: String?
    @State private var feedbackCategory: FeedbackCategory?
    
    var body: some View {
        List {
            Section {
                NavigationLink(destination: wordDefinitionView(word: nil)) {
                    HStack {
                        Image(systemName: "shuffle")
                            .foregroundColor(.blue)
                        Text("Random Word")
                    }
                }
            }
            
            // Filter words that have at least one meaning
            Section("Your Words") {
                ForEach(words.filter { !$0.meanings.isEmpty }) { word in
                    NavigationLink(destination: wordDefinitionView(word: word)) {
                        HStack {
                            Text(word.wordText)
                            Spacer()
                            
                            HStack(spacing: 8) {
                                if word.isConfident {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                }
                                
                                if word.isFavorite {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func wordDefinitionView(word: Word?) -> some View {
        let selectedWord = word ?? words.filter { !$0.meanings.isEmpty }.randomElement()
        return Group {
            if let currentWord = selectedWord {
                VStack(spacing: 20) {
                    Text(currentWord.wordText)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    
                    if let evaluation = evaluationResult {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your definition:")
                                .font(.headline)
                            Text(userDefinition)
                                .font(.body)
                                .padding()
                                .background(Color(uiColor: .systemGray6))
                                .cornerRadius(8)
                            
                            if let category = feedbackCategory {
                                FeedbackView(category: category, evaluation: evaluation)
                            }
                            
                            Button("Next Word") {
                                self.currentWord = words.filter { !$0.meanings.isEmpty }.randomElement()
                                self.userDefinition = ""
                                self.evaluationResult = nil
                                self.feedbackCategory = nil
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top)
                        }
                        .padding()
                        .transition(.opacity)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Write a definition for the word:")
                                .font(.headline)
                            
                            TextField("Enter your definition...", text: $userDefinition, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                            
                            Button("Submit") {
                                Task {
                                    isEvaluating = true
                                    evaluationResult = await evaluateDefinition(word: currentWord.wordText, definition: userDefinition)
                                    isEvaluating = false
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(userDefinition.isEmpty || isEvaluating)
                        }
                        .padding()
                    }
                }
                .navigationTitle("Definition Writing")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("No words available")
                    .font(.headline)
            }
        }
        .onAppear {
            if selectedWord == nil {
                self.currentWord = words.filter { !$0.meanings.isEmpty }.randomElement()
            } else {
                self.currentWord = selectedWord
            }
            self.userDefinition = ""
            self.evaluationResult = nil
            self.feedbackCategory = nil
        }
    }
    
    private func evaluateDefinition(word: String, definition: String) async -> String {
        do {
            let message = """
            As a language expert, evaluate if this definition for the word "\(word)" is accurate:
            "\(definition)"
            
            Evaluate the definition based on these criteria:
            1. Accuracy: Is the definition correct and precise?
            2. Completeness: Does it cover the essential aspects of the word's meaning?
            3. Clarity: Is the explanation clear and well-structured?
            4. Depth: Does it show understanding of the word's nuances and usage?
            5. Originality: Does it demonstrate personal understanding rather than just memorization?
            
            Provide a detailed explanation of the strengths and areas for improvement in the definition.
            
            At the end of your response, categorize the definition into exactly ONE of these categories:
            - EXCEPTIONAL: Perfect definition showing deep understanding and mastery
            - EXCELLENT: Strong definition with minor room for improvement
            - GOOD: Correct definition with some room for enhancement
            - FAIR: Basic understanding with significant room for improvement
            - NEEDS_IMPROVEMENT: Incorrect or incomplete understanding
            
            Format your category as: CATEGORY: [category_name]
            """
            let response = try await chat.sendMessage(message)
            let responseText = response.text ?? "Could not evaluate the definition."
            
            // Determine feedback category from the response
            if responseText.contains("CATEGORY: EXCEPTIONAL") {
                self.feedbackCategory = .exceptional
            } else if responseText.contains("CATEGORY: EXCELLENT") {
                self.feedbackCategory = .excellent
            } else if responseText.contains("CATEGORY: GOOD") {
                self.feedbackCategory = .good
            } else if responseText.contains("CATEGORY: FAIR") {
                self.feedbackCategory = .fair
            } else if responseText.contains("CATEGORY: NEEDS_IMPROVEMENT") {
                self.feedbackCategory = .needsImprovement
            } else {
                self.feedbackCategory = .good // Default if no category found
            }
            
            // Remove the category from the displayed text
            let cleanedText = responseText.replacingOccurrences(of: #"CATEGORY: (EXCEPTIONAL|EXCELLENT|GOOD|FAIR|NEEDS_IMPROVEMENT)"#, with: "", options: .regularExpression)
            
            return cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print(error)
            self.feedbackCategory = .needsImprovement
            return "Error evaluating the definition."
        }
    }
} 