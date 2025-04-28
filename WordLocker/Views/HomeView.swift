import SwiftUI
import SwiftData
// Import services for direct adding
import Foundation // For UUID
import Combine // If needed for debouncing or other async ops
import UniformTypeIdentifiers // Needed for file importer

// Assuming WordService and PhraseService are accessible
// If not, ensure they are properly imported or available globally/via environment


struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Word.createdAt) private var words: [Word]
    @Query(sort: \Phrase.createdAt) private var phrases: [Phrase]
    @Query(sort: \Collection.createdAt) private var collections: [Collection]
    @AppStorage("defaultSortOrder") private var defaultSortOrder = "dateAdded"
    @State private var isMenuOpen = false
    @State private var isAddWordPresented = false
    @State private var isAddCollectionPresented = false
    @State private var selectedWord: Word?
    @State private var selectedPhrase: Phrase?
    @State private var searchText = ""
    @State private var showingAddWord = false
    @State private var sortOptions: Set<SortOption>
    @State private var isSortModalPresented = false
    @State private var selectedCollectionName: String?
    @State private var itemFilter: ItemFilter = .all
    @State private var searchConfidentWords: Bool?
    @State private var collectionToEdit: Collection?
    @FocusState private var isSearchFocused: Bool
    @State private var isPremiumViewPresented = false // State for premium modal
    @State private var wordToNavigateTo: Word? = nil // Changed for word-only navigation
    @State private var showAddOption: Bool = false // State to control showing the "Add" option
    @State private var isExportModalPresented = false // State for export modal
    @State private var isImporting = false // State for file importer sheet
    @State private var showImportAlert = false // State for showing the import result alert
    @State private var importAlertMessage = "" // Message for the import result alert

    // Debouncer for search text to avoid rapid updates
    @State private var searchTextDebounced = ""
    private let searchDebouncer = PassthroughSubject<String, Never>()


    init() {
        // Initialize sortOptions based on defaultSortOrder
        let initialSortOption: SortOption
        switch UserDefaults.standard.string(forKey: "defaultSortOrder") ?? "newestFirst" {
        case "oldestFirst":
            initialSortOption = .dateAdded(ascending: true)
        case "alphabeticalAscending":
            initialSortOption = .alphabetically(ascending: true)
        case "alphabeticalDescending":
            initialSortOption = .alphabetically(ascending: false)
        default:
            initialSortOption = .dateAdded(ascending: false)
        }
        _sortOptions = State(initialValue: [initialSortOption])
    }
    
    enum ItemFilter: Hashable {
        case all
        case words
        case phrases
    }
    
    struct Item: Identifiable {
        let id: UUID
        let text: String
        let notes: String? // Make optional for AddItem
        let isFavorite: Bool? // Make optional for AddItem
        let isConfident: Bool? // Make optional for AddItem
        let createdAt: Date? // Make optional for AddItem
        let isPhrase: Bool? // Make optional for AddItem
        let word: Word?
        let phrase: Phrase?
        let isAddItemPlaceholder: Bool // Flag for the special "Add" item

        // Initializer for existing Word
        init(word: Word) {
            self.id = word.id
            self.text = word.wordText
            self.notes = word.notes
            self.isFavorite = word.isFavorite
            self.isConfident = word.isConfident
            self.createdAt = word.createdAt
            self.isPhrase = false
            self.word = word
            self.phrase = nil
            self.isAddItemPlaceholder = false
        }

        // Initializer for existing Phrase
        init(phrase: Phrase) {
            self.id = phrase.id
            self.text = phrase.phraseText
            self.notes = phrase.notes
            self.isFavorite = phrase.isFavorite
            self.isConfident = false // Phrases don't have confidence level
            self.createdAt = phrase.createdAt
            self.isPhrase = true
            self.word = nil
            self.phrase = phrase
            self.isAddItemPlaceholder = false
        }

        // Initializer for the "Add Item" placeholder
        init(addItemPlaceholder text: String) {
            self.id = UUID() // Unique ID for the placeholder
            self.text = text // Will be like "Add '[searchText]'"
            self.notes = nil
            self.isFavorite = nil
            self.isConfident = nil
            self.createdAt = nil
            self.isPhrase = nil // Type determined on add
            self.word = nil
            self.phrase = nil
            self.isAddItemPlaceholder = true
        }
    }
    
    // Computed property for unique collections in the side menu
    var uniqueCollections: [Collection] {
        var seenNames = Set<String>()
        return collections.filter { collection in
            seenNames.insert(collection.name.lowercased()).inserted // Keep if name hasn't been seen (case-insensitive)
        }
    }

    // Computed property for filtered items including the "Add" option
    var displayedItems: [Item] {
        // --- Start Filtering Logic ---
        let baseWords = if let collectionName = selectedCollectionName {
            if collectionName == "Favorites" {
                Word.fetchAll(modelContext: modelContext, sortBy: sortOptions.first ?? .dateAdded(ascending: false)) // Use actual words query
                    .filter { $0.isFavorite } // Filter for favorites
            } else {
                Word.fetchWordsInCollection(collectionName: collectionName, modelContext: modelContext, sortBy: sortOptions.first ?? .dateAdded(ascending: false)) // Fetch by collection
            }
        } else {
            Word.fetchAll(modelContext: modelContext, sortBy: sortOptions.first ?? .dateAdded(ascending: false)) // Fetch all words
        }

        let basePhrases = if let collectionName = selectedCollectionName {
            if collectionName == "Favorites" {
                Phrase.fetchAll(modelContext: modelContext, sortBy: sortOptions.first ?? .dateAdded(ascending: false)) // Use actual phrases query
                    .filter { $0.isFavorite } // Filter for favorites
            } else {
                Phrase.fetchPhrasesInCollection(collectionName: collectionName, modelContext: modelContext, sortBy: sortOptions.first ?? .dateAdded(ascending: false)) // Fetch by collection
            }
        } else {
            Phrase.fetchAll(modelContext: modelContext, sortBy: sortOptions.first ?? .dateAdded(ascending: false)) // Fetch all phrases
        }

        // Convert to Items and combine
        let combinedItems = baseWords.map { Item(word: $0) } + basePhrases.map { Item(phrase: $0) }

        // --- Deduplication Logic ---
        var deduplicatedItems: [Item] = []
        var seenTexts = Set<String>()

        for item in combinedItems {
            let lowercasedText = item.text.lowercased()
            if !seenTexts.contains(lowercasedText) {
                deduplicatedItems.append(item)
                seenTexts.insert(lowercasedText)
            }
            // If text is already seen, skip this item (it's a duplicate)
        }
        // --- End Deduplication Logic ---

        // Use deduplicatedItems for further processing
        var items = deduplicatedItems

        // Apply search filter if needed (using debounced text)
        let effectiveSearchText = searchTextDebounced.trimmingCharacters(in: .whitespacesAndNewlines)
        if !effectiveSearchText.isEmpty {
            items = items.filter { item in
                item.text.localizedCaseInsensitiveContains(effectiveSearchText)
            }
        }

        // Apply item type filter (only if not searching, or if search yields results)
        if effectiveSearchText.isEmpty || !items.isEmpty {
            switch itemFilter {
            case .all:
                break // Show everything
            case .words:
                items = items.filter { $0.word != nil } // Filter to words
                // Apply confidence subfilter if set
                if let isConfident = searchConfidentWords {
                    items = items.filter { $0.isConfident == isConfident }
                }
            case .phrases:
                items = items.filter { $0.phrase != nil } // Filter to phrases
            }
        }

        // Sort based on current sort option (only if not showing add option)
        if items.isEmpty && !effectiveSearchText.isEmpty {
             // If search yields no results, show the "Add" placeholder
             // Use a specific ID or handle differently in the view
             return [Item(addItemPlaceholder: "Add \"\(effectiveSearchText)\"...")]
        } else {
            // Otherwise, apply sorting
            switch sortOptions.first {
            case .dateAdded(let ascending):
                // Ensure createdAt is not nil before sorting
                items.sort { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) ? ascending : !ascending }
            case .alphabetically(let ascending):
                items.sort { $0.text.localizedCaseInsensitiveCompare($1.text) == (ascending ? .orderedAscending : .orderedDescending) }
            case .none:
                break // No sorting
            }

            // --- Filter out predefined items ONLY for the "All" view ---
            let hiddenTag = "_predefined_secret_"
            if selectedCollectionName == nil {
                items = items.filter { item in
                    // Ensure word/phrase is not nil before accessing collectionNames
                    let names = item.isPhrase == true ? item.phrase?.collectionNames : item.word?.collectionNames
                    return !(names?.contains(hiddenTag) ?? false)
                }
            }
            // --- End filter ---
            return items
        }
    }
    // --- End Filtering Logic ---


    var currentCollectionName: String {
        selectedCollectionName ?? "Word Locker"
    }
    
    func onAddClick() {
//        let totalItemCount = words.count + phrases.count
//
//        if totalItemCount >= 50 {
//            isPremiumViewPresented = true
//        } else {
//            isAddWordPresented = true
//        }
        
        isAddWordPresented = true
    }
    
    func isDeviceAniPad_SwiftUI() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Cork board background
                    Color(red: 0.86, green: 0.75, blue: 0.6)
                        .ignoresSafeArea()
                        .overlay(
                            Image(systemName: "circle.grid.cross.fill")
                                .foregroundColor(.brown.opacity(0.1))
                                .font(.system(size: 20))
                        )
                    
                    VStack(spacing: 0) {
                        // Header with a paper-like texture
                        HStack {
                            HStack(spacing: 16) {
                                Button(action: {
                                    withAnimation(.spring()) {
                                        isMenuOpen.toggle()
                                    }
                                }) {
                                    Image(systemName: "line.3.horizontal")
                                        .font(.title2)
                                        .foregroundColor(.black)
                                }
                                // Import/Export buttons moved to side menu
                            }

                            Spacer()
                            
                            Text(currentCollectionName)
                                .font(.custom("Marker Felt", size: 24))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                            
                            Spacer()

                            HStack(spacing: 16) {
                                // Learn button moved to side menu
                                NavigationLink(destination: SettingsView()) {
                                    Image(systemName: "gear")
                                        .font(.title2)
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        .padding(.top, geometry.size.height * 0.05)
                        .padding(.horizontal)
                        .frame(height: isDeviceAniPad_SwiftUI() ? geometry.size.height * 0.09 : geometry.size.height * 0.12)
                        
                        .background(
                            ZStack {
                                Color.white
                                    .opacity(0.9)
                                    .shadow(radius: 2)
                                
                                // Add bottom border
                                VStack {
                                    Rectangle()
                                        .frame(height: 2)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Rectangle()
                                        .frame(height: 2)
                                        .foregroundColor(.black)
                                }
                            }
                        )
                        .edgesIgnoringSafeArea(.top)
                        
                        // Filter Picker
                        VStack(spacing: 8) {
                            CustomSegmentedControl(
                                selection: Binding(
                                    get: {
                                        switch itemFilter {
                                        case .all: return 0
                                        case .words: return 1
                                        case .phrases: return 2
                                        }
                                    },
                                    set: { newValue in
                                        switch newValue {
                                        case 0: itemFilter = .all
                                        case 1: itemFilter = .words
                                        case 2: itemFilter = .phrases
                                        default: break
                                        }
                                    }
                                ),
                                items: ["All", "Words", "Phrases"]
                            )
                            .padding(.horizontal)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black.opacity(1), lineWidth: 2)
                                    .padding(.horizontal)
                            )
                            
                            // Show confidence filter only when Words filter is selected
                            if itemFilter == .words {
                                // Subfilter buttons
                                HStack {
                                    Text("Show: ")
                                        .font(.custom("Marker Felt", size: 16))
                                        .foregroundColor(.brown)
                                    
                                    Button(action: { 
                                        searchConfidentWords = nil
                                    }) {
                                        Text("All Words")
                                            .font(.custom("Marker Felt", size: 16))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(searchConfidentWords == nil ? Color.blue : Color.clear)
                                            .foregroundColor(searchConfidentWords == nil ? .black : .brown)
                                            .cornerRadius(8)
                                    }
                                    
                                    Button(action: {
                                        searchConfidentWords = true
                                    }) {
                                        Text("Confident")
                                            .font(.custom("Marker Felt", size: 16))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(searchConfidentWords == true ? Color.green : Color.clear)
                                            .foregroundColor(searchConfidentWords == true ? .black : .brown)
                                            .cornerRadius(8)
                                    }
                                    
                                    Button(action: {
                                        searchConfidentWords = false
                                    }) {
                                        Text("Learning")
                                            .font(.custom("Marker Felt", size: 16))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(searchConfidentWords == false ? Color.orange : Color.clear)
                                            .foregroundColor(searchConfidentWords == false ? .black : .brown)
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, isDeviceAniPad_SwiftUI() ? 0 : -geometry.size.height * 0.035)
                        .padding(.bottom, geometry.size.height * 0.02)
                        
                        // Updated Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.black)
                            TextField("Search words and phrases...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.custom("BradleyHandITCTT-Bold", size: 16))
                                .focused($isSearchFocused)
                                .submitLabel(.search) // Change label for clarity
                                .onSubmit {
                                    // Trigger debounced update immediately on submit
                                    searchTextDebounced = searchText
                                    isSearchFocused = false
                                }
                                .onChange(of: searchText) { _, newValue in
                                     // Send changes to the debouncer
                                     searchDebouncer.send(newValue)
                                 }
                                .onReceive(searchDebouncer.debounce(for: .milliseconds(300), scheduler: RunLoop.main)) { debouncedText in
                                     // Update the debounced state after delay
                                     searchTextDebounced = debouncedText
                                 }

                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = "" // Clear immediately
                                    searchTextDebounced = "" // Clear debounced too
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.black)
                                }
                            }
                            
                            Menu {
                                Button(action: { sortOptions = [.dateAdded(ascending: false)] }) {
                                    Label("Newest First", systemImage: "arrow.down.circle")
                                }
                                Button(action: { sortOptions = [.dateAdded(ascending: true)] }) {
                                    Label("Oldest First", systemImage: "arrow.up.circle")
                                }
                                Button(action: { sortOptions = [.alphabetically(ascending: true)] }) {
                                    Label("A to Z", systemImage: "textformat.abc")
                                }
                                Button(action: { sortOptions = [.alphabetically(ascending: false)] }) {
                                    Label("Z to A", systemImage: "textformat.abc")
                                }
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .foregroundColor(.black)
                            }
                        }
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
                        .padding(.horizontal)
                        .onAppear {
                            // Update sort options based on default sort order
                            switch defaultSortOrder {
                            case "oldestFirst":
                                sortOptions = [.dateAdded(ascending: true)]
                            case "alphabeticalAscending":
                                sortOptions = [.alphabetically(ascending: true)]
                            case "alphabeticalDescending":
                                sortOptions = [.alphabetically(ascending: false)]
                            default:
                                sortOptions = [.dateAdded(ascending: false)]
                            }
                        }
                        
                        // Word, Phrase Cards, or "Add" Option List
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(displayedItems) { item in
                                    if item.isAddItemPlaceholder {
                                        // Special view/button for adding the item
                                        Button(action: {
                                            addItemDirectly(text: searchText) // Use original searchText
                                        }) {
                                            HStack {
                                                Image(systemName: "plus.circle.fill")
                                                Text(item.text) // Shows "Add '[searchText]'..."
                                                    .font(.custom("Marker Felt", size: 18))
                                            }
                                            .foregroundColor(.black)
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(Color.green.opacity(0.3)) // Distinct background
                                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 3)
                                                            .stroke(Color.black.opacity(1), lineWidth: 2)
                                                    )
                                            )
                                        }
                                    } else {
                                        // Existing item card
                                        ItemCardView(word: item.word, phrase: item.phrase)
                                            .frame(height: geometry.size.height * 0.125) // Make height responsive
                                            .onTapGesture {
                                                if item.phrase != nil {
                                                    selectedPhrase = item.phrase
                                                } else if item.word != nil {
                                                    selectedWord = item.word
                                                }
                                            }
                                    }
                                }
                            }
                            .padding()
                        }
                    }

                    // Update the add button to look more playful
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: onAddClick) {
                                Image(systemName: "plus")
                                    .font(.title)
                                    .foregroundColor(.black)
                                    .frame(width: geometry.size.width * 0.15, height: geometry.size.width * 0.15)
                                    .background(
                                        ZStack {
                                            Circle()
                                                .fill(Color.yellow) // Soft yellow post-it color
                                                .shadow(color: .black.opacity(0.2), radius: 3, x: 2, y: 2)
                                            
                                            // Add a subtle paper texture effect
                                            Circle()
                                                .fill(Color.white.opacity(0.1))
                                                .background(.ultraThinMaterial)
                                            
                                            // Add border as a separate layer
                                            Circle()
                                                .stroke(Color.black.opacity(1), lineWidth: 2)
                                                .padding(1)
                                        }
                                    )
                                    .clipShape(Circle()) // Ensure the entire button is circular
                                    .rotationEffect(.degrees(.random(in: -3...3)))
                                    .offset(x: .random(in: -2...2), y: .random(in: -2...2))
                            }
                            .padding(.bottom, geometry.size.height * 0.03)
                            Spacer()
                        }
                    }
                    
                    // Side Menu
                    ZStack {
                        if isMenuOpen {
                            Color.black
                                .opacity(0.3)
                                .ignoresSafeArea()
                                .transition(.opacity)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isMenuOpen = false
                                    }
                                }
                        }
                        
                        HStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: geometry.size.height * 0.03) {
                                Text("Menu")
                                    .font(.custom("Marker Felt", size: 24))
                                    .foregroundColor(.black)
                                    .padding(.top, geometry.size.height * 0.06)

                                Button(action: {
                                    isImporting = true
                                    isMenuOpen = false // Close menu on action
                                }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                            .foregroundColor(.black)
                                        Text("Import CSV")
                                            .font(.custom("Marker Felt", size: 16))
                                            .foregroundColor(.black)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }

                                Button(action: {
                                    isExportModalPresented = true
                                    isMenuOpen = false // Close menu on action
                                }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundColor(.black)
                                        Text("Export CSV")
                                            .font(.custom("Marker Felt", size: 16))
                                            .foregroundColor(.black)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }

                                NavigationLink(destination: LearningView()) {
                                    HStack {
                                        Image(systemName: "brain.head.profile")
                                            .foregroundColor(.black)
                                        Text("Learn")
                                            .font(.custom("Marker Felt", size: 16))
                                            .foregroundColor(.black)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                    isMenuOpen = false // Close menu on navigation
                                })
                                
                                NavigationLink(destination: StatsView()) { // <-- Stats Link Moved Here
                                    HStack {
                                        Image(systemName: "chart.bar.xaxis")
                                            .foregroundColor(.black)
                                        Text("Statistics")
                                            .font(.custom("Marker Felt", size: 16))
                                            .foregroundColor(.black)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                     isMenuOpen = false // Close menu on navigation
                                 })
                                // --- End Moved Options ---
                                
                                // --- Moved Options ---
                                Divider().background(Color.gray.opacity(0.5)) // Visual separator
                                
                                // Header Section
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Collections")
                                            .font(.custom("Marker Felt", size: 24))
                                            .foregroundColor(.black)
                                        
                                        Spacer()
                                        
                                        Button(action: { isAddCollectionPresented = true }) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.black)
                                        }
                                    }
                                }
                                .padding(.bottom, 8)


                                // Collections List (Scrollable)
                                ScrollView { // Wrap the list in a ScrollView
                                    VStack(alignment: .leading, spacing: 12) { // Keep items in a VStack inside ScrollView
                                        Button(action: { selectedCollectionName = nil }) {
                                            HStack {
                                                Text("All")
                                                .font(.custom("Marker Felt", size: 16))
                                                .foregroundColor(.black)
                                                .multilineTextAlignment(.leading) // Add this
                                            Spacer()
                                            if selectedCollectionName == nil {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.black)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    
                                    Button(action: { selectedCollectionName = "Favorites" }) {
                                        HStack {
                                            Text("Favorites")
                                                .font(.custom("Marker Felt", size: 16))
                                                .foregroundColor(.black)
                                                .multilineTextAlignment(.leading) // Add this
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                                .padding(.bottom, 3)
                                            Spacer()
                                            if selectedCollectionName == "Favorites" {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.black)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    
                                    ForEach(uniqueCollections) { collection in // Use uniqueCollections here
                                        HStack {
                                            Button(action: {
                                                selectedCollectionName = collection.name // Keep original collection object for selection
                                            }) {
                                                HStack {
                                                    Text(collection.name)
                                                        .font(.custom("Marker Felt", size: 16))
                                                        .foregroundColor(.black)
                                                        .multilineTextAlignment(.leading) // Add this
                                                    Spacer()
                                                    if selectedCollectionName == collection.name {
                                                        Image(systemName: "checkmark")
                                                            .foregroundColor(.black)
                                                    }
                                                }
                                                .padding(.vertical, 8)
                                            }
                                            
                                            Menu {
                                                Button(action: {
                                                    collectionToEdit = collection
                                                }) {
                                                    Label("Edit", systemImage: "pencil")
                                                }
                                                
                                                Button(role: .destructive, action: {
                                                    Collection.delete(collection, modelContext: modelContext)
                                                }) {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            } label: {
                                                Image(systemName: "ellipsis.circle")
                                                    .foregroundColor(.black.opacity(0.6))
                                            }
                                        }
                                    } // End ForEach
                                } // End VStack inside ScrollView
                                .padding(.bottom) // Add padding at the bottom of the scrollable content
                            } // End ScrollView


                                Spacer() // Spacer remains outside the ScrollView
                            }
                            .padding()
                            .frame(width: geometry.size.width * 0.525)
                            .background(
                                ZStack {
                                    Color.white
                                        .opacity(0.95)
                                    
                                    // Add subtle texture
                                    Color.brown.opacity(0.05)
                                        .background(.ultraThinMaterial)
                                }
                            )
                            .edgesIgnoringSafeArea(.vertical)
                            .zIndex(1)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 0)
                            .offset(x: isMenuOpen ? 0 : -geometry.size.width)
                            
                            Spacer()
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: isMenuOpen)
                }
                .onTapGesture {
                    isSearchFocused = false
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.commaSeparatedText], // Allow only CSV
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    // Start the import process
                    Task {
                        await importCSV(from: url)
                    }
                case .failure(let error):
                    print("Error selecting file: \(error.localizedDescription)")
                    // Optionally show an error alert to the user
                    importAlertMessage = "Error selecting file: \(error.localizedDescription)"
                    showImportAlert = true
                }
            }
            .alert("Import Results", isPresented: $showImportAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importAlertMessage)
            }
            .sheet(isPresented: $isExportModalPresented) {
                // Present the actual ExportView, assuming environment objects are provided upstream
                ExportView()
            }
            .sheet(isPresented: $isAddWordPresented) {
                ItemFormView(mode: .add)
            }
            .sheet(isPresented: $isAddCollectionPresented) {
                AddCollectionView(mode: .add)
            }
            .sheet(item: $selectedWord) { word in
                // Pass callback to handle navigation requests
                WordDetailsView(word: word, navigateTo: handleNavigationRequest)
            }
            .sheet(item: $selectedPhrase) { phrase in
                // Phrases no longer need the navigateTo callback
                PhraseDetailsView(phrase: phrase)
            }
            .sheet(item: $collectionToEdit) { collection in
                AddCollectionView(mode: .edit(collection))
            }
//            .sheet(isPresented: $isPremiumViewPresented) { // Add sheet for PremiumView
//                PremiumView()
//            }
            // Handle navigation requests from WordDetailsView
            .onChange(of: wordToNavigateTo) { _, newWord in
                if let newWord = newWord {
                    // Dismiss current sheet first
                    selectedWord = nil
                    selectedPhrase = nil // Ensure phrase sheet is also dismissed if open

                    // Short delay to allow dismissal animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        selectedWord = newWord
                        // Reset wordToNavigateTo after handling
                        wordToNavigateTo = nil
                    }
                }
            }
        }
        .accentColor(.black) // Set back button color to black
    }

    // Callback function for WordDetailsView to request navigation
    // Function to determine if text is a phrase
    private func isPhrase(_ text: String) -> Bool {
        return text.trimmingCharacters(in: .whitespacesAndNewlines).contains(" ")
    }

    // Function to add item directly
    @MainActor
    private func addItemDirectly(text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        // Check for duplicates before adding
        let existingWords = Word.fetchAll(modelContext: modelContext)
        let existingPhrases = Phrase.fetchAll(modelContext: modelContext)

        let isDuplicateWord = existingWords.contains { $0.wordText.lowercased() == trimmedText.lowercased() }
        let isDuplicatePhrase = existingPhrases.contains { $0.phraseText.lowercased() == trimmedText.lowercased() }

        if isDuplicateWord || isDuplicatePhrase {
            // Optionally show an alert or feedback that it already exists
            print("Item '\(trimmedText)' already exists.")
            // Clear search text even if duplicate? Or leave it? Let's clear it.
             searchText = ""
             searchTextDebounced = ""
            return // Exit if duplicate
        }

        // If not a duplicate, proceed to add
        if isPhrase(trimmedText) {
            // Add as Phrase using PhraseService
            // Reconstruct the createPhrase call correctly
             let newPhrase = PhraseService.shared.createPhrase(
                 text: trimmedText,
                 notes: "", // Default empty notes
                 isFavorite: false, // Default not favorite
                 collectionNames: [] // Default no collections
             )
            PhraseService.shared.savePhrase(newPhrase, modelContext: modelContext)
            print("Added Phrase: \(trimmedText)")
        } else {
            // Add as Word using WordService (needs async handling)
            Task {
                 let newWord = await WordService.shared.createWord(
                     text: trimmedText,
                     notes: "", // Default empty notes
                     isFavorite: false, // Default not favorite
                     isConfident: false, // Default not confident
                     collectionNames: [] // Default no collections
                 )
                 if let wordToSave = newWord {
                     WordService.shared.saveWord(wordToSave, modelContext: modelContext)
                     print("Added Word: \(trimmedText)")
                 } else {
                     print("Error creating word: \(trimmedText)")
                     // Handle error if needed
                 }
            }
        }

        // Clear search text after adding
        searchText = ""
        searchTextDebounced = ""
        isSearchFocused = false // Dismiss keyboard
    }

    // Callback function for WordDetailsView to request navigation
    private func handleNavigationRequest(word: Word) {
        wordToNavigateTo = word
    }

    // Function to handle CSV import
    @MainActor
    private func importCSV(from url: URL) async {
        // Securely access the file URL
        guard url.startAccessingSecurityScopedResource() else {
            importAlertMessage = "Failed to access file."
            showImportAlert = true
            return
        }

        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let csvData = try String(contentsOf: url, encoding: .utf8)
            let rows = csvData.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            guard rows.count > 1 else { // Check if there's more than just a header
                importAlertMessage = "CSV file is empty or contains only a header."
                showImportAlert = true
                return
            }

            // Simple CSV parsing (assumes comma delimiter, handles basic quotes)
            // More robust parsing might be needed for complex CSVs
            var addedCount = 0
            var skippedCount = 0

            // Fetch existing items for duplicate check (Optimization)
            let existingWordsLowercased = Set(Word.fetchAll(modelContext: modelContext).map { $0.wordText.lowercased() })
            let existingPhrasesLowercased = Set(Phrase.fetchAll(modelContext: modelContext).map { $0.phraseText.lowercased() })

            // Sets to track items added *during this import* to prevent duplicates within the CSV
            var addedWordsInBatch = Set<String>()
            var addedPhrasesInBatch = Set<String>()

            // Skip header row (index 0)
            for rowString in rows.dropFirst() {
                let columns = parseCSVRow(rowString) // Use a helper for parsing
                guard columns.count >= 1, !columns[0].isEmpty else { continue } // Need at least the item text

                let itemText = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let notesText = columns.count > 1 ? columns[1].trimmingCharacters(in: .whitespacesAndNewlines) : ""
                let itemTextLowercased = itemText.lowercased()

                // Check for duplicates (existing in DB OR already added in this batch)
                if existingWordsLowercased.contains(itemTextLowercased) || existingPhrasesLowercased.contains(itemTextLowercased) ||
                   addedWordsInBatch.contains(itemTextLowercased) || addedPhrasesInBatch.contains(itemTextLowercased) {
                    skippedCount += 1
                    continue // Skip duplicate
                }

                // Check if it's a phrase or a word
                if isPhrase(itemText) {
                    // Create and save a Phrase
                    let newPhrase = Phrase(phraseText: itemText) // Use basic initializer
                    newPhrase.notes = notesText
                    modelContext.insert(newPhrase)
                    addedPhrasesInBatch.insert(itemTextLowercased) // Track added phrase
                    print("Imported Phrase: \(itemText)")
                } else {
                    // Create and save a Word
                    let newWord = await Word(wordText: itemText) // Use await for the async initializer
                    newWord.notes = notesText
                    modelContext.insert(newWord)
                    addedWordsInBatch.insert(itemTextLowercased) // Track added word
                    print("Imported Word: \(itemText)")
                }
                addedCount += 1
            }

            // Save changes after processing all rows
            try modelContext.save()

            importAlertMessage = "Import Complete!\nAdded: \(addedCount)\nSkipped (duplicates): \(skippedCount)"

        } catch {
            print("Error reading or processing CSV: \(error)")
            importAlertMessage = "Error processing CSV file: \(error.localizedDescription)"
        }

        showImportAlert = true // Show the results alert
    }

    // Helper function to parse a single CSV row (handles simple quotes)
    private func parseCSVRow(_ row: String) -> [String] {
        var columns: [String] = []
        var currentColumn = ""
        var inQuotes = false

        for character in row {
            switch character {
            case "\"":
                inQuotes.toggle()
            case "," where !inQuotes:
                columns.append(currentColumn)
                currentColumn = ""
            default:
                currentColumn.append(character)
            }
        }
        columns.append(currentColumn) // Add the last column
        // Trim quotes from results if needed
        return columns.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
    }
}


struct ItemCardView: View {
    let word: Word?
    let phrase: Phrase?
    @State private var rotation: Double = .random(in: -3...3)
    @State private var offset: CGSize = CGSize(
        width: .random(in: -5...5),
        height: .random(in: -5...5)
    )
    
    var text: String {
        word?.wordText ?? phrase?.phraseText ?? ""
    }
    
    var notes: String {
        word?.notes ?? phrase?.notes ?? ""
    }
    
    var isFavorite: Bool {
        word?.isFavorite ?? phrase?.isFavorite ?? false
    }
    
    var isPhrase: Bool {
        return phrase != nil
    }
    
    var postItColor: Color {
        if isPhrase {
            return Color(red: 0.78, green: 0.87, blue: 0.97) // Soft blue that complements both red and green
        } else {
            return word?.isConfident == true ? 
                Color(red: 0.87, green: 0.97, blue: 0.78) : // Sage green
                Color(red: 0.97, green: 0.78, blue: 0.87)   // Dusty rose
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            Spacer()
            
            Text(text)
                .font(.custom("BradleyHandITCTT-Bold", size: 28))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                postItColor
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 2, y: 2)
                
                // Add a subtle paper texture effect
                Color.white.opacity(0.1)
                    .background(.ultraThinMaterial)
                
                // Add border as a separate layer
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.black.opacity(1), lineWidth: 3)
                    .padding(1)
            }
        )
        .cornerRadius(3)
    }
}
