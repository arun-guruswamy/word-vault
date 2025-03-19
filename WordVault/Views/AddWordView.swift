import SwiftUI
import SwiftData

struct AddWordView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var wordText = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Word")) {
                    TextField("Word or phrase", text: $wordText)
                }
                
                Section(header: Text("Notes"), footer: Text("Add any personal notes about this word")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add New Word")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    Task {
                        let newWord = await Word(wordText: wordText)
                        newWord.notes = notes
                        Word.save(newWord, modelContext: modelContext)
                        dismiss()
                    }
                }
                .disabled(wordText.isEmpty)
            )
        }
    }
}
