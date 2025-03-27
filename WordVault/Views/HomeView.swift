import SwiftUI
import SwiftData

struct CustomSegmentedControl: UIViewRepresentable {
    @Binding var selection: Int
    let items: [String]
    
    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = selection
        control.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        
        // Customize appearance
        control.backgroundColor = .clear
        control.setTitleTextAttributes([
            .font: UIFont(name: "BradleyHandITCTT-Bold", size: 16) ?? .systemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ], for: .normal)
        
        control.setTitleTextAttributes([
            .font: UIFont(name: "BradleyHandITCTT-Bold", size: 16) ?? .systemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ], for: .selected)
        
        return control
    }
    
    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        uiView.selectedSegmentIndex = selection
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: CustomSegmentedControl
        
        init(_ parent: CustomSegmentedControl) {
            self.parent = parent
        }
        
        @objc func valueChanged(_ sender: UISegmentedControl) {
            parent.selection = sender.selectedSegmentIndex
        }
    }
}

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
        let notes: String
        let isFavorite: Bool
        let isConfident: Bool
        let createdAt: Date
        let isPhrase: Bool
        let word: Word?
        let phrase: Phrase?
        
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
        }
        
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
        }
    }
    
    var filteredItems: [Item] {
        let words = if let collectionName = selectedCollectionName {
            if collectionName == "Favorites" {
                Word.fetchAll(modelContext: modelContext, sortBy: sortOptions.first ?? .dateAdded(ascending: false))
                    .filter { $0.isFavorite }
            } else {
                Word.fetchWordsInCollection(collectionName: collectionName, modelContext: modelContext, sortBy: sortOptions.first ?? .dateAdded(ascending: false))
            }
        } else {
            Word.fetchAll(modelContext: modelContext, sortBy: sortOptions.first ?? .dateAdded(ascending: false))
        }
        
        let phrases = if let collectionName = selectedCollectionName {
            if collectionName == "Favorites" {
                Phrase.fetchAll(modelContext: modelContext, sortBy: sortOptions.first ?? .dateAdded(ascending: false))
                    .filter { $0.isFavorite }
            } else {
                Phrase.fetchPhrasesInCollection(collectionName: collectionName, modelContext: modelContext, sortBy: sortOptions.first ?? .dateAdded(ascending: false))
            }
        } else {
            Phrase.fetchAll(modelContext: modelContext, sortBy: sortOptions.first ?? .dateAdded(ascending: false))
        }
        
        // Convert to Items and combine
        var items = words.map { Item(word: $0) } + phrases.map { Item(phrase: $0) }
        
        // Apply search filter if needed
        if !searchText.isEmpty {
            items = items.filter { item in
                item.text.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply item type filter
        switch itemFilter {
        case .all:
            break // Show everything
        case .words:
            items = items.filter { !$0.isPhrase } // First filter to words
            
            // Apply confidence subfilter if set
            if let isConfident = searchConfidentWords {
                items = items.filter { $0.isConfident == isConfident }
            }
        case .phrases:
            items = items.filter { $0.isPhrase }
        }
        
        // Sort based on current sort option
        switch sortOptions.first {
        case .dateAdded(let ascending):
            items.sort { ascending ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt }
        case .alphabetically(let ascending):
            items.sort { ascending ? $0.text < $1.text : $0.text > $1.text }
        case .none:
            break
        }
        
        return items
    }
    
    var currentCollectionName: String {
        selectedCollectionName ?? "Word Vault"
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
                                // Just to keep title in center
                                Image(systemName: "brain.head.profile")
                                    .font(.title2)
                                    .foregroundColor(.clear)
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
                                NavigationLink(destination: LearningView()) {
                                    Image(systemName: "brain.head.profile")
                                        .font(.title2)
                                        .foregroundColor(.black)
                                }
                                
                                NavigationLink(destination: SettingsView()) {
                                    Image(systemName: "gear")
                                        .font(.title2)
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        .padding(.top, geometry.size.height * 0.05)
                        .padding(.horizontal)
                        .frame(height: geometry.size.height * 0.12)
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
                                        .font(.custom("BradleyHandITCTT-Bold", size: 16))
                                        .foregroundColor(.brown)
                                    
                                    Button(action: { 
                                        searchConfidentWords = nil
                                    }) {
                                        Text("All Words")
                                            .font(.custom("BradleyHandITCTT-Bold", size: 16))
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
                                            .font(.custom("BradleyHandITCTT-Bold", size: 16))
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
                                            .font(.custom("BradleyHandITCTT-Bold", size: 16))
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
                        .padding(.top, -geometry.size.height * 0.035)
                        .padding(.bottom, geometry.size.height * 0.02)
                        
                        // Updated Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.brown.opacity(0.6))
                            TextField("Search words and phrases...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.custom("BradleyHandITCTT-Bold", size: 16))
                                .focused($isSearchFocused)
                                .submitLabel(.done)
                                .onSubmit {
                                    isSearchFocused = false
                                }
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
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
                        
                        // Word and Phrase Cards List
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredItems) { item in
                                    ItemCardView(word: item.word, phrase: item.phrase)
                                        .frame(height: geometry.size.height * 0.125) // Make height responsive
                                        .onTapGesture {
                                            if item.isPhrase {
                                                selectedPhrase = item.phrase
                                            } else {
                                                selectedWord = item.word
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
                            Button(action: { isAddWordPresented = true }) {
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
                                .padding(.top, geometry.size.height * 0.06)
                                .padding(.bottom, 8)
                                
                                // Collections List
                                VStack(alignment: .leading, spacing: 12) {
                                    Button(action: { selectedCollectionName = "Favorites" }) {
                                        HStack {
                                            Text("Favorites")
                                                .font(.custom("Marker Felt", size: 16))
                                                .foregroundColor(.black)
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
                                    
                                    ForEach(collections) { collection in
                                        HStack {
                                            Button(action: {
                                                selectedCollectionName = collection.name
                                            }) {
                                                HStack {
                                                    Text(collection.name)
                                                        .font(.custom("Marker Felt", size: 16))
                                                        .foregroundColor(.black)
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
                                    }
                                }
                                .padding(.vertical, 8)
                                
                                Spacer()
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
            .sheet(isPresented: $isAddWordPresented) {
                ItemFormView(mode: .add)
            }
            .sheet(isPresented: $isAddCollectionPresented) {
                AddCollectionView(mode: .add)
            }
            .sheet(item: $selectedWord) { word in
                WordDetailsView(word: word)
            }
            .sheet(item: $selectedPhrase) { phrase in
                PhraseDetailsView(phrase: phrase)
            }
            .sheet(item: $collectionToEdit) { collection in
                AddCollectionView(mode: .edit(collection))
            }
        }
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
