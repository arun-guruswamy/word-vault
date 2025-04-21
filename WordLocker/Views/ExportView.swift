import SwiftUI
import SwiftData // Import SwiftData
import UniformTypeIdentifiers // Needed for UTType.commaSeparatedText

struct ExportView: View {
    @Environment(\.modelContext) private var modelContext // Use modelContext
    // Removed EnvironmentObject properties
    @Environment(\.dismiss) var dismiss

    // State for filtering options
    // TODO: Fetch actual collections for the Picker
    @Query(sort: \Collection.name) private var collections: [Collection] // Fetch collections for picker

    @State private var selectedCollectionId: String? = nil // nil means all collections
    @State private var exportWords = true
    @State private var exportPhrases = true
    // Add more filter states as needed (e.g., learning status, date range)

    @State private var showDocumentPicker = false
    @State private var csvFileURL: URL?
    
    func generateCSV() {
        var csvString = "Item\n" // Header Row - Only the item itself

        do {
            // Determine the target collection name *within* the do-catch block if needed
            var targetCollectionName: String? = nil
            if let collectionUUIDString = selectedCollectionId,
               let collectionUUID = UUID(uuidString: collectionUUIDString) {
                // Fetch the specific collection by ID to get its name
                let collectionDescriptor = FetchDescriptor<Collection>(predicate: #Predicate { $0.id == collectionUUID })
                if let collection = try modelContext.fetch(collectionDescriptor).first {
                    targetCollectionName = collection.name
                } else {
                    // Handle case where the selected ID doesn't match any collection
                    print("Error: Could not find collection with ID: \(collectionUUIDString)")
                    // Optionally show an alert to the user
                    return // Stop export if collection not found
                }
            }

            // --- Fetch Words ---
            if exportWords {
                // Fetch ALL words first
                let allWordsDescriptor = FetchDescriptor<Word>(sortBy: [SortDescriptor(\Word.wordText)])
                let allWords = try modelContext.fetch(allWordsDescriptor)

                // Filter in memory if a specific collection is selected
                let wordsToExport: [Word]
                if let name = targetCollectionName {
                    wordsToExport = allWords.filter { $0.collectionNames.contains(name) }
                } else {
                    // If "All Collections", use all fetched words
                    wordsToExport = allWords
                }

                for word in wordsToExport {
                    csvString += escape(word.wordText) + "\n" // Append only the word text
                }
            }

            // --- Fetch Phrases ---
            if exportPhrases {
                // Fetch ALL phrases first
                let allPhrasesDescriptor = FetchDescriptor<Phrase>(sortBy: [SortDescriptor(\Phrase.phraseText)])
                let allPhrases = try modelContext.fetch(allPhrasesDescriptor)

                // Filter in memory if a specific collection is selected
                let phrasesToExport: [Phrase]
                if let name = targetCollectionName {
                    phrasesToExport = allPhrases.filter { $0.collectionNames.contains(name) }
                } else {
                    // If "All Collections", use all fetched phrases
                    phrasesToExport = allPhrases
                }

                for phrase in phrasesToExport {
                    csvString += escape(phrase.phraseText) + "\n" // Append only the phrase text
                }
            }
        } catch {
            print("Error fetching data for export: \(error)")
            // Handle fetch error (e.g., show an alert to the user)
            return // Stop execution if fetch fails
        }

        // Save CSV string to a temporary file
        saveCSVToFile(csvString)
    }

    // Removed formatCSVRow function as it's no longer needed for single-column export

    // Helper function to escape CSV fields (still needed for the single item)
    func escape(_ field: String) -> String {
        let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
        // Only quote if necessary (contains comma, quote, or newline)
        if escapedField.contains(",") || escapedField.contains("\"") || escapedField.contains("\n") {
            return "\"\(escapedField)\""
        }
        return escapedField
    }


    func saveCSVToFile(_ csvString: String) {
        guard let data = csvString.data(using: .utf8) else {
            print("Error: Could not convert CSV string to data")
            // Handle error appropriately (e.g., show alert)
            return
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("WordVault_Export_\(Date().timeIntervalSince1970).csv")

        do {
            try data.write(to: tempURL, options: .atomic)
            self.csvFileURL = tempURL
            self.showDocumentPicker = true // Trigger the share sheet/document picker
        } catch {
            print("Error saving CSV file: \(error)")
            // Handle error appropriately
        }
    }

    var body: some View {
        // Use NavigationStack for consistency if other views use it
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

                Form {
                    // Corrected Section Structure
                    Section {
                        // Picker is now directly inside the Section
                        Picker("Collection", selection: $selectedCollectionId) {
                            Text("All Collections").tag(String?.none)
                            ForEach(collections) { collection in
                                Text(collection.name).tag(collection.id.uuidString as String?)
                            }
                        }
                        .font(.custom("Marker Felt", size: 16)) // Apply font to Picker content

                        // Toggles are now directly inside the Section
                        Toggle("Export Words", isOn: $exportWords)
                            .font(.custom("Marker Felt", size: 16))
                        Toggle("Export Phrases", isOn: $exportPhrases)
                            .font(.custom("Marker Felt", size: 16))

                        // Add more filter controls here if needed
                    } header: { // Header is correctly applied to the Section
                        Text("Filter Options")
                            .font(.custom("Marker Felt", size: 18))
                            .foregroundColor(.black)
                    }
                    .listRowBackground(Color.white.opacity(0.7)) // Style list row

                    Section { // Second Section (Export Format)
                            Text("CSV (Comma Separated Values)")
                                .font(.custom("Marker Felt", size: 16)) // Apply font
                            // Potentially add other formats later (JSON, etc.)
                        } header: {
                            Text("Export Format") // Apply header text
                                .font(.custom("Marker Felt", size: 18))
                                .foregroundColor(.black)
                        }
                        .listRowBackground(Color.white.opacity(0.7)) // Style list row
                        
                        // Button Section for better spacing/layout if needed
                        Section {
                            Button(action: generateCSV) {
                                Text("Generate Export File")
                                    .font(.custom("Marker Felt", size: 18))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity) // Make button wider
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.brown.opacity(0.8)) // Match other buttons
                                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 3)
                                                    .stroke(Color.black, lineWidth: 2)
                                            )
                                    )
                            }
                            .buttonStyle(.plain) // Remove default button styling if needed
                            .disabled(!exportWords && !exportPhrases)
                        }
                        .listRowBackground(Color.clear) // Make button section background clear
                        
                    }
                    .scrollContentBackground(.hidden) // Hide default List background
                }
                .navigationBarTitleDisplayMode(.inline) // Match other views
                .toolbar {
                    ToolbarItem(placement: .principal) { // Center title
                        Text("Export Data")
                            .font(.custom("Marker Felt", size: 20))
                            .foregroundColor(.black)
                    }
                    ToolbarItem(placement: .navigationBarLeading) { // Use ToolbarItem for cancel
                        Button("Cancel") { dismiss() }
                            .font(.custom("Marker Felt", size: 16))
                            .foregroundColor(.black)
                    }
                }
                .sheet(isPresented: $showDocumentPicker) {
                    // Present the document picker (or share sheet)
                    if let url = csvFileURL {
                        ActivityViewController(activityItems: [url])
                    }
                }
            }
        }
    }

// Helper for Share Sheet (ActivityViewController)
struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
