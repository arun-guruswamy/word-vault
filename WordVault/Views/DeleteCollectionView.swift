import SwiftUI
import SwiftData

struct DeleteCollectionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var collections: [Collection]
    @State private var selectedCollections: Set<Collection> = []
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Collections to Delete")) {
                    ForEach(collections) { collection in
                        Button(action: {
                            if selectedCollections.contains(collection) {
                                selectedCollections.remove(collection)
                            } else {
                                selectedCollections.insert(collection)
                            }
                        }) {
                            HStack {
                                Text(collection.name)
                                Spacer()
                                if selectedCollections.contains(collection) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                
                if !selectedCollections.isEmpty {
                    Section {
                        Text("\(selectedCollections.count) collection\(selectedCollections.count == 1 ? "" : "s") selected")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Delete Collections")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Delete") {
                    for collection in selectedCollections {
                        Collection.delete(collection, modelContext: modelContext)
                    }
                    dismiss()
                }
                .disabled(selectedCollections.isEmpty)
                .foregroundColor(.red)
            )
        }
    }
} 