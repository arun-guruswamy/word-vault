import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var words: [Word]
    @State private var isMenuOpen = false
    @State private var isAddWordPresented = false
    @State private var selectedWord: Word?
    @State private var searchText = ""
    @State private var showingAddWord = false
    @State private var sortOptions: Set<SortOption> = [.dateAdded(ascending: false)]
    @State private var isSortModalPresented = false
    
    var filteredWords: [Word] {
        if searchText.isEmpty {
            return Word.fetchAll(modelContext: modelContext, sortBy: sortOptions.first ?? .dateAdded(ascending: false))
        } else {
            return Word.search(query: searchText, modelContext: modelContext, sortBy: sortOptions.first ?? .dateAdded(ascending: false))
        }
    }
    
    var body: some View {
        ZStack {
            // Main Content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { isMenuOpen.toggle() }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Text("Word Vault")
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
                .padding(8)
                .background(Color(uiColor: .systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 15)
                
                // Word Cards List
                ScrollView {
                    LazyVStack(spacing: 16) {
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
            
            // Side Menu
            if isMenuOpen {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isMenuOpen = false
                    }
                
                HStack {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Menu")
                            .font(.title)
                            .padding(.top, 50)
                        
                        ForEach(["Profile", "Categories", "Favorites", "History"], id: \.self) { menuItem in
                            Text(menuItem)
                                .font(.headline)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .frame(width: 250)
                    .background(Color(uiColor: .systemBackground))
                    .edgesIgnoringSafeArea(.vertical)
                    
                    Spacer()
                }
                .transition(.move(edge: .leading))
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
                            .frame(width: 60, height: 60)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.bottom, 20)
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $isAddWordPresented) {
            AddWordView()
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
