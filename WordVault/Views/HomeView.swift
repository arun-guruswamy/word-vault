import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var words: [Word]
    @State private var isMenuOpen = false
    @State private var isAddWordPresented = false
    @State private var selectedWord: Word?
    @State private var searchText = ""
    
    var filteredWords: [Word] {
        if searchText.isEmpty {
            return words
        }
        return Word.search(query: searchText, modelContext: modelContext)
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
                    .padding()
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
            
            Text(word.definition)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct WordDetailView: View {
    let word: Word
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text(word.wordText)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Definition")
                    .font(.headline)
                Text(word.definition)
                    .font(.body)
                
                Text("Example")
                    .font(.headline)
                Text(word.example)
                    .font(.body)
                    .italic()
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Word.self)
}
