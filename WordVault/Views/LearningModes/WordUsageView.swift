import SwiftUI
import SwiftData
import MarkdownUI

struct WordUsageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Word.createdAt) private var words: [Word]
    @State private var currentWord: Word?
    @State private var userSentence = ""
    @State private var isEvaluating = false
    @State private var evaluationResult: String?
    @State private var feedbackCategory: FeedbackCategory?
    @State private var showMissingWordAlert = false
    
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
                            Text("Your sentence:")
                                .font(.headline)
                            Text(userSentence)
                                .font(.body)
                                .padding()
                                .background(Color(uiColor: .systemGray6))
                                .cornerRadius(8)
                            
                            if let category = feedbackCategory {
                                FeedbackView(category: category, evaluation: evaluation)
                            }
                            
                            Button("Next Word") {
                                self.currentWord = words.filter { !$0.meanings.isEmpty }.randomElement()
                                self.userSentence = ""
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
                            Text("Create a sentence using the word:")
                                .font(.headline)
                            
                            TextField("Enter your sentence...", text: $userSentence, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                            
                            Button("Submit") {
                                if containsWord(sentence: userSentence, word: currentWord.wordText) {
                                    Task {
                                        isEvaluating = true
                                        evaluationResult = await evaluateSentence(word: currentWord.wordText, sentence: userSentence)
                                        isEvaluating = false
                                    }
                                } else {
                                    showMissingWordAlert = true
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(userSentence.isEmpty || isEvaluating)
                        }
                        .padding()
                    }
                }
                .navigationTitle("Word Usage")
                .navigationBarTitleDisplayMode(.inline)
                .alert("Missing Word", isPresented: $showMissingWordAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Your sentence doesn't include the word '\(currentWord.wordText)'. Please make sure to use the word in your sentence.")
                }
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
            self.userSentence = ""
            self.evaluationResult = nil
            self.feedbackCategory = nil
        }
    }
    
    private func containsWord(sentence: String, word: String) -> Bool {
        // Convert both to lowercase for case-insensitive comparison
        let sentenceLower = sentence.lowercased()
        let wordLower = word.lowercased()
        
        // Split the sentence into words
        let words = sentenceLower.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
        
        // Check if the word is in the sentence
        return words.contains(wordLower)
    }
    
    private func evaluateSentence(word: String, sentence: String) async -> String {
        do {
            let message = """
            As a language expert, evaluate if the word "\(word)" is used correctly in this sentence:
            "\(sentence)"
            
            Evaluate the response based on these criteria:
            1. Accuracy: Is the word used correctly according to its meaning?
            2. Context: Is the word used in an appropriate context?
            3. Creativity: Does the usage show originality and depth of understanding?
            4. Clarity: Is the meaning clear and well-expressed?
            5. Complexity: Does the usage demonstrate understanding of the word's nuances?
            
            Provide a detailed explanation of the strengths and areas for improvement in the usage.
            
            At the end of your response, categorize the usage into exactly ONE of these categories:
            - EXCEPTIONAL: Perfect usage showing deep understanding, creativity, and mastery
            - EXCELLENT: Strong usage with minor room for improvement
            - GOOD: Correct usage with some room for enhancement
            - FAIR: Basic understanding with significant room for improvement
            - NEEDS_IMPROVEMENT: Incorrect or inappropriate usage
            
            Format your category as: CATEGORY: [category_name]
            """
            let response = try await chat.sendMessage(message)
            let responseText = response.text ?? "Could not evaluate the sentence."
            
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
            return "Error evaluating the sentence."
        }
    }
} 