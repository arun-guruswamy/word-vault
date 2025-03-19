import SwiftUI
import SwiftData
import Foundation

struct WordDetailView: View {
    let word: Word
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isEditPresented = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(word.wordText)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("Added on \(word.createdAt.formatted(date: .long, time: .shortened))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 15)
                    
                    if word.meanings.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            VStack(spacing: 4) {
                                Text("No information found")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(word.meanings, id: \.partOfSpeech) { meaning in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(meaning.partOfSpeech.capitalized)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                
                                ForEach(meaning.definitions.indices, id: \.self) { index in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("\(index + 1). \(meaning.definitions[index].definition)")
                                            .font(.body)
                                        
                                        if let example = meaning.definitions[index].example {
                                            Text("Example: \(example)")
                                                .font(.body)
                                                .italic()
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.bottom, 8)
                                }
                            }
                            .padding(.bottom, 16)
                        }
                    }
                    
                    if !word.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Personal Notes")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text(word.notes)
                                .font(.body)
                        }
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarItems(
                leading: Button("Done") {
                    dismiss()
                },
                trailing: HStack {
                    Button(action: { isEditPresented = true }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        Word.delete(word, modelContext: modelContext)
                        dismiss()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            )
            .sheet(isPresented: $isEditPresented) {
                EditWordView(word: word)
            }
            .padding(.trailing, 12.5)
            .padding(.leading, 12.5)
        }
    }
}

struct EditWordView: View {
    let word: Word
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var wordText: String
    @State private var notes: String
    
    init(word: Word) {
        self.word = word
        _wordText = State(initialValue: word.wordText)
        _notes = State(initialValue: word.notes)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Word")) {
                    TextField("Word", text: $wordText)
                }
                
                Section(header: Text("Notes"), footer: Text("Add any personal notes about this word")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Word")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    Task {
                        if wordText != word.wordText {
                            // Update word text and try to fetch new definitions
                            if let entry = try? await DictionaryService.shared.fetchDefinition(for: wordText) {
                                // If word exists in dictionary, update with new data
                                word.wordText = wordText
                                word.definition = entry.meanings.first?.definitions.first?.definition ?? "No definition found"
                                word.example = entry.meanings.first?.definitions.first?.example ?? "No example available"
                                word.meanings = entry.meanings.map { meaning in
                                    Word.WordMeaning(
                                        partOfSpeech: meaning.partOfSpeech,
                                        definitions: meaning.definitions.map { def in
                                            Word.WordDefinition(
                                                definition: def.definition,
                                                example: def.example
                                            )
                                        }
                                    )
                                }
                            } else {
                                // If word doesn't exist in dictionary, update word text and clear dictionary data
                                word.wordText = wordText
                                word.definition = "No definition found"
                                word.example = "No example available"
                                word.meanings = []
                            }
                        }
                        word.notes = notes
                        try? modelContext.save()
                        dismiss()
                    }
                }
                .disabled(wordText.isEmpty)
            )
        }
    }
}
