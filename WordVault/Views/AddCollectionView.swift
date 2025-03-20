import SwiftUI
import SwiftData

struct AddCollectionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var collectionName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Collection Name")) {
                    TextField("Enter collection name", text: $collectionName)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    let collection = Collection(name: collectionName)
                    Collection.save(collection, modelContext: modelContext)
                    dismiss()
                }
                .disabled(collectionName.isEmpty)
            )
        }
    }
} 