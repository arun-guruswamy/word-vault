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
    @State private var searchText = ""
    
    var filteredWords: [Word] {
        let wordsWithMeanings = words.filter { !$0.meanings.isEmpty }
        
        if searchText.isEmpty {
            return wordsWithMeanings
        } else {
            return wordsWithMeanings.filter { word in
                word.wordText.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color matching the app
                Color(red: 0.86, green: 0.75, blue: 0.6)
                    .ignoresSafeArea()
                    .overlay(
                        Image(systemName: "circle.grid.cross.fill")
                            .foregroundColor(.brown.opacity(0.1))
                            .font(.system(size: 20))
                    )
                
                List {
                    // Search Bar
                    Section {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.black)
                            TextField("Search words...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.custom("BradleyHandITCTT-Bold", size: 16))
                                .submitLabel(.search)
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.white.opacity(0.7))
                    
                    // Filter words that have at least one meaning
                    Section {
                        ForEach(filteredWords) { word in
                            NavigationLink(destination: wordDefinitionView(word: word)) {
                                HStack {
                                    Text(word.wordText)
                                        .font(.custom("BradleyHandITCTT-Bold", size: 16))
                                        .foregroundColor(.black)
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        if word.isConfident {
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Your Words")
                            .font(.custom("Marker Felt", size: 18))
                            .foregroundColor(.black)
                    }
                    .listRowBackground(Color.white.opacity(0.7))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Definition Writing")
                        .font(.custom("Marker Felt", size: 20))
                        .foregroundColor(.black)
                }
            }
        }
    }
    
    private func wordDefinitionView(word: Word) -> some View {
        ZStack {
            // Background color matching the app
            Color(red: 0.86, green: 0.75, blue: 0.6)
                .ignoresSafeArea()
                .overlay(
                    Image(systemName: "circle.grid.cross.fill")
                        .foregroundColor(.brown.opacity(0.1))
                        .font(.system(size: 20))
                )
            
            ScrollView {
                VStack(spacing: 20) {
                    Text(word.wordText)
                        .font(.custom("Marker Felt", size: 30))
                        .foregroundColor(.black)
                        .padding()
                        .id("wordHeader-\(word.id)")  // Add a stable ID to prevent recreation
                    
                    if let evaluation = evaluationResult {
                        evaluationResultView(evaluation: evaluation, definition: userDefinition)
                    } else {
                        inputFormView(word: word)
                        
                        if isEvaluating {
                            loadingView
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .padding()
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Definition Writing")
                    .font(.custom("Marker Felt", size: 20))
                    .foregroundColor(.black)
            }
        }
        .id(word.id)  // Add a stable ID to prevent recreation
        .onAppear {
            self.currentWord = word
            self.userDefinition = ""
            self.evaluationResult = nil
            self.feedbackCategory = nil
        }
    }
    
    // Loading animation view
    private var loadingView: some View {
        VStack {
            Text("Getting feedback...")
                .font(.custom("Marker Felt", size: 16))
                .foregroundColor(.black)
                .padding(.bottom, 8)
            
            HStack(spacing: 12) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.brown)
                        .frame(width: 12, height: 12)
                        .opacity(0.4)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(0.2 * Double(index)),
                            value: isEvaluating
                        )
                        .scaleEffect(isEvaluating ? 1.2 : 0.8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.black, lineWidth: 2)
                )
        )
        .padding()
    }
    
    @ViewBuilder
    private func evaluationResultView(evaluation: String, definition: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your definition:")
                .font(.custom("Marker Felt", size: 18))
                .foregroundColor(.black)
                
            Text(definition)
                .font(.custom("BradleyHandITCTT-Bold", size: 16))
                .foregroundColor(.black)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.black, lineWidth: 2)
                        )
                )
            
            if let category = feedbackCategory {
                FeedbackView(category: category, evaluation: evaluation)
            }
            
            Button("Try Again") {
                self.userDefinition = ""
                self.evaluationResult = nil
                self.feedbackCategory = nil
            }
            .font(.custom("Marker Felt", size: 16))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.brown.opacity(0.8))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.black, lineWidth: 2)
                    )
            )
            .foregroundColor(.white)
            .padding(.top)
        }
        .padding()
        .transition(.opacity)
    }
    
    @ViewBuilder
    private func inputFormView(word: Word) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Write a definition for the word:")
                .font(.custom("Marker Felt", size: 18))
                .foregroundColor(.black)
            
            TextField("Enter your definition...", text: $userDefinition, axis: .vertical)
                .font(.custom("BradleyHandITCTT-Bold", size: 16))
                .foregroundColor(.black)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.black, lineWidth: 2)
                        )
                )
                .lineLimit(3...6)
            
            Button("Submit") {
                Task {
                    isEvaluating = true
                    evaluationResult = await evaluateDefinition(word: word.wordText, definition: userDefinition)
                    isEvaluating = false
                }
            }
            .font(.custom("Marker Felt", size: 16))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.brown.opacity(0.8))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.black, lineWidth: 2)
                    )
            )
            .foregroundColor(.white)
            .disabled(userDefinition.isEmpty || isEvaluating)
        }
        .padding()
    }
    
    private func evaluateDefinition(word: String, definition: String) async -> String {
        do {
            let message = """
            As a language expert, evaluate if this definition for the word "\(word)" is accurate:
            "\(definition)"
            
            BE VERY CONCISE in your feedback. Provide no more than 2-3 short sentences focusing only on the most important points.
            
            First, quickly determine if the definition is:
            1. Accurate and complete
            2. Somewhat accurate but missing elements
            3. Inaccurate or off-target
            
            Then provide your brief feedback focusing on the most important issue.
            
            At the end, categorize the definition as: EXCEPTIONAL, EXCELLENT, GOOD, FAIR, or NEEDS_IMPROVEMENT
            
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
