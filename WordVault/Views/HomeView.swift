import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Word.createdAt) private var words: [Word]
    @Query(sort: \Phrase.createdAt) private var phrases: [Phrase]
    @Query(sort: \Collection.createdAt) private var collections: [Collection]
    @State private var isMenuOpen = false
    @State private var isAddWordPresented = false
    @State private var isAddCollectionPresented = false
    @State private var isDeleteCollectionPresented = false
    @State private var selectedWord: Word?
    @State private var selectedPhrase: Phrase?
    @State private var searchText = ""
    @State private var showingAddWord = false
    @State private var sortOptions: Set<SortOption> = [.dateAdded(ascending: false)]
    @State private var isSortModalPresented = false
    @State private var selectedCollectionName: String?
    @State private var itemFilter: ItemFilter = .all
    @State private var isLearningPresented = false
    
    enum ItemFilter {
        case all
        case words
        case phrases
    }
    
    struct Item: Identifiable {
        let id: UUID
        let text: String
        let notes: String
        let isFavorite: Bool
        let createdAt: Date
        let isPhrase: Bool
        let word: Word?
        let phrase: Phrase?
        
        init(word: Word) {
            self.id = word.id
            self.text = word.wordText
            self.notes = word.notes
            self.isFavorite = word.isFavorite
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
            break
        case .words:
            items = items.filter { !$0.isPhrase }
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
                    // Main Content
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isMenuOpen.toggle()
                                }
                            }) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Text(currentCollectionName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            HStack(spacing: 16) {
                                Button(action: { isLearningPresented = true }) {
                                    Image(systemName: "brain.head.profile")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                }
                                
                                NavigationLink(destination: SettingsView()) {
                                    Image(systemName: "gear")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .systemBackground))
                        .shadow(radius: 2)
                        
                        // Filter Picker
                        Picker("Filter", selection: $itemFilter) {
                            Text("All").tag(ItemFilter.all)
                            Text("Words").tag(ItemFilter.words)
                            Text("Phrases").tag(ItemFilter.phrases)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search words and phrases...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
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
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, geometry.size.height * 0.02)
                        .background(Color(uiColor: .systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.top, geometry.size.height * 0.01)
                        
                        // Word and Phrase Cards List
                        ScrollView {
                            LazyVStack(spacing: geometry.size.height * 0.02) {
                                ForEach(filteredItems) { item in
                                    ItemCardView(word: item.word, phrase: item.phrase)
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
                    
                    // Add Button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: { isAddWordPresented = true }) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: geometry.size.width * 0.15, height: geometry.size.width * 0.15)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
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
                        
                        HStack {
                            VStack(alignment: .leading, spacing: geometry.size.height * 0.03) {
                                Text("Collections")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, geometry.size.height * 0.06)
                                
                                Button(action: { selectedCollectionName = nil }) {
                                    HStack {
                                        Text("All")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                        Spacer()
                                        if selectedCollectionName == nil {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                
                                Button(action: { selectedCollectionName = "Favorites" }) {
                                    HStack {
                                        Text("Favorites")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                        Spacer()
                                        if selectedCollectionName == "Favorites" {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                
                                ForEach(collections) { collection in
                                    Button(action: {
                                        selectedCollectionName = collection.name
                                    }) {
                                        HStack {
                                            Text(collection.name)
                                                .font(.subheadline)
                                                .foregroundColor(.black)
                                            Spacer()
                                            if selectedCollectionName == collection.name {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Divider()
                                
                                Button(action: { isAddCollectionPresented = true }) {
                                    Label("New Collection", systemImage: "folder.badge.plus")
                                        .font(.subheadline)
                                }
                                
                                Button(action: { isDeleteCollectionPresented = true }) {
                                    Label("Delete Collections", systemImage: "folder.badge.minus")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                }
                                .padding(.bottom, geometry.size.height * 0.03)
                            }
                            .padding()
                            .frame(width: geometry.size.width * 0.525)
                            .background(Color(uiColor: .systemBackground))
                            .edgesIgnoringSafeArea(.vertical)
                            .zIndex(1)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 0)
                            .offset(x: isMenuOpen ? 0 : -geometry.size.width)
                            
                            Spacer()
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: isMenuOpen)
                }
            }
            .sheet(isPresented: $isAddWordPresented) {
                ItemFormView(mode: .add)
            }
            .sheet(isPresented: $isAddCollectionPresented) {
                AddCollectionView()
            }
            .sheet(isPresented: $isDeleteCollectionPresented) {
                DeleteCollectionView()
            }
            .sheet(item: $selectedWord) { word in
                WordDetailsView(word: word)
            }
            .sheet(item: $selectedPhrase) { phrase in
                PhraseDetailsView(phrase: phrase)
            }
            .sheet(isPresented: $isLearningPresented) {
                LearningView()
            }
        }
    }
}

struct ItemCardView: View {
    let word: Word?
    let phrase: Phrase?
    
    init(word: Word? = nil, phrase: Phrase? = nil) {
        self.word = word
        self.phrase = phrase
    }
    
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
        print("here")
        return phrase != nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(text)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                if isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Text(notes.isEmpty ? "No notes were added" : notes)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .italic(notes.isEmpty)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(isPhrase ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}
