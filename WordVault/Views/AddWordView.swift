import SwiftUI
import SwiftData

struct AddWordView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var wordText = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Word", text: $wordText)
            }
            .navigationTitle("Add New Word")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    Task {
                        let newWord = await Word(wordText: wordText)
                        Word.save(newWord, modelContext: modelContext)
                        dismiss()
                    }
                }
                .disabled(wordText.isEmpty)
            )
        }
    }
}
