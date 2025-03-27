import SwiftUI
import SwiftData

struct AddCollectionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var collectionName = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Collection Name")) {
                    TextField("Enter collection name", text: $collectionName)
                        .onChange(of: collectionName) { _, newValue in
                            if newValue.count > 20 {
                                collectionName = String(newValue.prefix(20))
                            }
                        }
                }
            }
            .navigationTitle("New Collection")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    let trimmedName = collectionName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedName.isEmpty {
                        let collection = Collection(name: trimmedName)
                        Collection.save(collection, modelContext: modelContext)
                        dismiss()
                    } else {
                        showingAlert = true
                    }
                }
                .disabled(collectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
            .alert("Invalid Name", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Collection name cannot be empty or contain only whitespace.")
            }
        }
    }
} 