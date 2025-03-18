import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var itemText = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Item", text: $itemText)
            }
            .navigationTitle("Add New Item")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    let newItem = Item(itemText: itemText)
                    Item.save(newItem, modelContext: modelContext)
                    dismiss()
                }
                .disabled(itemText.isEmpty)
            )
        }
    }
}
