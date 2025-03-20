import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var words: [Word]
    @Query(sort: \Collection.createdAt, order: .reverse) private var collections: [Collection]
    @State private var isMenuOpen = false
    @State private var isAddWordPresented = false
    @State private var isAddCollectionPresented = false
    @State private var isDeleteCollectionPresented = false
    @State private var selectedWord: Word?
    @State private var searchText = ""
    @State private var showingAddWord = false
    @State private var sortOptions: Set<SortOption> = [.dateAdded(ascending: false)]
    @State private var isSortModalPresented = false
    @State private var selectedCollectionName: String?
    
    var filteredWords: [Word] {
        if let collectionName = selectedCollectionName {
            if collectionName == "Favorites" {
                return Word.fetchAll(modelContext: modelContext, sortBy: sortOptions.first ?? .dateAdded(ascending: false))
                    .filter { $0.isFavorite }
            }
            return Word.fetchWordsInCollection(collectionName: collectionName, modelContext: modelContext, sortBy: sortOptions.first ?? .dateAdded(ascending: false))
        }
        
        if searchText.isEmpty {
            return Word.fetchAll(modelContext: modelContext, sortBy: sortOptions.first ?? .dateAdded(ascending: false))
        } else {
            return Word.search(query: searchText, modelContext: modelContext, sortBy: sortOptions.first ?? .dateAdded(ascending: false))
        }
    }
    
    var currentCollectionName: String {
        selectedCollectionName ?? "All Words"
    }
    
    var body: some View {
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
                        
                        NavigationLink(destination: Text("Settings")) {
                            Image(systemName: "gear")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .systemBackground))
                    .shadow(radius: 2)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search words...", text: $searchText)
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
                    .padding(.top, geometry.size.height * 0.02)
                    
                    // Word Cards List
                    ScrollView {
                        LazyVStack(spacing: geometry.size.height * 0.02) {
                            ForEach(filteredWords) { word in
                                WordCardView(word: word)
                                    .onTapGesture {
                                        selectedWord = word
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
                                    Text("All Words")
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
            WordFormView(mode: .add)
        }
        .sheet(isPresented: $isAddCollectionPresented) {
            AddCollectionView()
        }
        .sheet(isPresented: $isDeleteCollectionPresented) {
            DeleteCollectionView()
        }
        .sheet(item: $selectedWord) { word in
            WordDetailView(word: word)
        }
    }
}

struct WordCardView: View {
    let word: Word
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(word.wordText)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(word.notes.isEmpty ? "No notes were added" : word.notes)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .italic(word.notes.isEmpty)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
