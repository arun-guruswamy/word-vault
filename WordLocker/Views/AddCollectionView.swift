import SwiftUI
import SwiftData

struct AddCollectionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var collectionName = ""
    @State private var showingEmptyNameAlert = false
    @State private var showingDuplicateNameAlert = false
    
    // Mode and existing collection (if editing)
    private let mode: Mode
    private let existingCollection: Collection?
    
    enum Mode: Hashable {
        case add
        case edit(Collection)
        
        static func == (lhs: Mode, rhs: Mode) -> Bool {
            switch (lhs, rhs) {
            case (.add, .add):
                return true
            case (.edit(let lhsCollection), .edit(let rhsCollection)):
                return lhsCollection.id == rhsCollection.id
            default:
                return false
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .add:
                hasher.combine(0)
            case .edit(let collection):
                hasher.combine(1)
                hasher.combine(collection.id)
            }
        }
    }
    
    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add:
            self.existingCollection = nil
            _collectionName = State(initialValue: "")
        case .edit(let collection):
            self.existingCollection = collection
            _collectionName = State(initialValue: collection.name)
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
                
                VStack(spacing: 20) {
                    // Collection Name Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Collection Name")
                            .font(.custom("Marker Felt", size: 20))
                            .foregroundColor(.black)
                        
                        TextField("Enter collection name", text: $collectionName)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.custom("BradleyHandITCTT-Bold", size: 16))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.9))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(Color.black.opacity(1), lineWidth: 2)
                                    )
                            )
                            .onChange(of: collectionName) { _, newValue in
                                if newValue.count > 20 {
                                    collectionName = String(newValue.prefix(20))
                                }
                            }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.custom("Marker Felt", size: 16))
                    .foregroundColor(.black)
                }
                ToolbarItem(placement: .principal) {
                    Text(mode == .add ? "New Collection" : "Edit Collection")
                        .font(.custom("Marker Felt", size: 20))
                        .foregroundColor(.black)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let trimmedName = collectionName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmedName.isEmpty {
                            showingEmptyNameAlert = true
                        } else {
                            switch mode {
                            case .add:
                                // Check for duplicate name
                                let existingCollections = Collection.fetchAll(modelContext: modelContext)
                                if existingCollections.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
                                    showingDuplicateNameAlert = true
                                } else {
                                    let collection = Collection(name: trimmedName)
                                    Collection.save(collection, modelContext: modelContext)
                                    dismiss()
                                }
                            case .edit(let collection):
                                // For editing, check for duplicate name only if the name has changed
                                if collection.name.lowercased() != trimmedName.lowercased() {
                                    let existingCollections = Collection.fetchAll(modelContext: modelContext)
                                    if existingCollections.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
                                        showingDuplicateNameAlert = true
                                    } else {
                                        collection.name = trimmedName
                                        try? modelContext.save()
                                        dismiss()
                                    }
                                } else {
                                    // Name hasn't changed, just dismiss
                                    dismiss()
                                }
                            }
                        }
                    }
                    .font(.custom("Marker Felt", size: 16))
                    .foregroundColor(.black)
                    .disabled(collectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            // Alert for empty name
            .alert("Invalid Name", isPresented: $showingEmptyNameAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Collection name cannot be empty or contain only whitespace.")
            }
            // Alert for duplicate name
            .alert("Duplicate Name", isPresented: $showingDuplicateNameAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A collection with this name already exists. Please choose a different name.")
            }
        }
    }
}
