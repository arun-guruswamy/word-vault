import SwiftUI
import SwiftData

struct LearningView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Word.createdAt) private var words: [Word]
    @Query(sort: \Phrase.createdAt) private var phrases: [Phrase]
    @State private var selectedMode: LearningMode?
    @State private var currentWord: Word?
    @State private var currentPhrase: Phrase?
    @State private var showAnswer = false
    @State private var score = 0
    @State private var totalQuestions = 0
    @State private var userSentence = ""
    @State private var isEvaluating = false
    @State private var evaluationResult: String?
    @State private var showWordSelection = false
    
    enum LearningMode: String, CaseIterable {
        case wordDefinition = "Word Definition"
        case phraseMeaning = "Phrase Meaning"
        case funFacts = "Fun Facts"
        case wordToPhrase = "Word to Phrase"
        
        var description: String {
            switch self {
            case .wordDefinition:
                return "Practice using words in sentences"
            case .phraseMeaning:
                return "Learn the meanings of common phrases"
            case .funFacts:
                return "Discover interesting facts about words"
            case .wordToPhrase:
                return "Match words to their related phrases"
            }
        }
        
        var icon: String {
            switch self {
            case .wordDefinition:
                return "book.fill"
            case .phraseMeaning:
                return "text.quote"
            case .funFacts:
                return "lightbulb.fill"
            case .wordToPhrase:
                return "link"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            if let mode = selectedMode {
                learningModeView(for: mode)
            } else {
                modeSelectionView
            }
        }
    }
    
    private var modeSelectionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Choose Learning Mode")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                ForEach(LearningMode.allCases, id: \.self) { mode in
                    Button(action: {
                        selectedMode = mode
                        if mode == .wordDefinition {
                            showWordSelection = true
                        } else {
                            startNewRound(mode: mode)
                        }
                    }) {
                        HStack {
                            Image(systemName: mode.icon)
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading) {
                                Text(mode.rawValue)
                                    .font(.headline)
                                Text(mode.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(uiColor: .systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Learning Center")
        .sheet(isPresented: $showWordSelection) {
            wordSelectionView
        }
    }
    
    private var wordSelectionView: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        startNewRound(mode: .wordDefinition)
                        showWordSelection = false
                    }) {
                        HStack {
                            Image(systemName: "shuffle")
                                .foregroundColor(.blue)
                            Text("Random Word")
                        }
                    }
                }
                
                Section("Your Words") {
                    ForEach(words.filter { !$0.meanings.isEmpty }) { word in
                        Button(action: {
                            currentWord = word
                            showWordSelection = false
                        }) {
                            HStack {
                                Text(word.wordText)
                                Spacer()
                                if word.isFavorite {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showWordSelection = false
                        selectedMode = nil
                    }
                }
            }
        }
    }
    
    private func learningModeView(for mode: LearningMode) -> some View {
        VStack {
            if let word = currentWord {
                VStack(spacing: 20) {
                    Text("Score: \(score)/\(totalQuestions)")
                        .font(.headline)
                        .padding(.top)
                    
                    Text(word.wordText)
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
                            
                            Text("Evaluation:")
                                .font(.headline)
                            Text(evaluation)
                                .font(.body)
                                .padding()
                                .background(Color(uiColor: .systemGray6))
                                .cornerRadius(8)
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
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    if evaluationResult == nil {
                        Button(action: {
                            Task {
                                isEvaluating = true
                                evaluationResult = await evaluateSentence(word: word.wordText, sentence: userSentence)
                                isEvaluating = false
                            }
                        }) {
                            if isEvaluating {
                                ProgressView("Evaluating...")
                            } else {
                                Text("Submit Sentence")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(userSentence.isEmpty || isEvaluating)
                        .padding()
                    } else {
                        Button("Try Another Word") {
                            resetRound()
                            showWordSelection = true
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                }
            } else {
                Text("No words available")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(mode.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    selectedMode = nil
                    resetRound()
                }
            }
        }
    }
    
    private func startNewRound(mode: LearningMode) {
        let availableWords = words.filter { !$0.meanings.isEmpty }
        if let randomWord = availableWords.randomElement() {
            currentWord = randomWord
            totalQuestions += 1
        }
    }
    
    private func resetRound() {
        currentWord = nil
        userSentence = ""
        evaluationResult = nil
        isEvaluating = false
    }
    
    private func evaluateSentence(word: String, sentence: String) async -> String {
        do {
            let message = """
            As a language expert, evaluate if the word "\(word)" is used correctly in this sentence:
            "\(sentence)"
            
            Provide a brief explanation of why the usage is correct or incorrect, and if incorrect, suggest a better way to use the word.
            """
            let response = try await chat.sendMessage(message)
            return response.text ?? "Could not evaluate the sentence."
        } catch {
            print(error)
            return "Error evaluating the sentence."
        }
    }
} 