import SwiftUI
import SwiftData
import Foundation
import MarkdownUI
import AVFoundation

struct WordDetailsView: View {
    let word: Word
    var navigateTo: ((Word) -> Void)? // Changed to expect Word
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isEditPresented = false
    @State private var isRefreshingFunFact: Bool = false
    @State private var errorMessage: String?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying: Bool = false
    @State private var isLoadingAudio: Bool = false
    @State private var isRefreshingDetails: Bool = false
    @State private var selectedTab = 0
    
    // Group meanings by part of speech
    private var groupedMeanings: [String: [Word.WordMeaning]] {
        Dictionary(grouping: word.meanings) { $0.partOfSpeech }
    }
    
    // Tab titles
    private let tabs = ["Meanings", "Notes", "Fun Fact", "Links"] // Shortened label
    @State private var isManageLinksPresented = false // State to present ManageLinksView
    @Query(sort: \Word.wordText) private var allWords: [Word] // Query for linked items view
    
    var body: some View {
        NavigationStack {
            mainContentView
        }
    }
    
    // MARK: - Main Content Views
    
    private var mainContentView: some View {
        ZStack {
            // Cork board background
            backgroundView
            
            VStack(spacing: 0) {
                // Word card header
                wordHeaderCard
                
                // Custom Tabs
                tabSelectionView
                
                // Tab content
                ScrollView {
                    VStack(spacing: 16) {
                        tabContentView
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    .padding(.horizontal)
                }
                .background(Color.white.opacity(0.6))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Word Details")
                    .font(.custom("Marker Felt", size: 20))
                    .foregroundColor(.black)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
                .font(.custom("Marker Felt", size: 16))
                .foregroundColor(.black)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: { isEditPresented = true }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.black)
                    }
                    
                    Button(role: .destructive, action: {
                        withAnimation {
                            Word.delete(word, modelContext: modelContext)
                            dismiss()
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $isEditPresented) {
            ItemFormView(mode: .editWord(word))
        }
        .sheet(isPresented: $isManageLinksPresented) { // Sheet for ManageLinksView
            ManageLinksView(word: word) // Pass the Word object directly
        }
    }
    
    private var backgroundView: some View {
        Color(red: 0.86, green: 0.75, blue: 0.6)
            .ignoresSafeArea()
            .overlay(
                Image(systemName: "circle.grid.cross.fill")
                    .foregroundColor(.brown.opacity(0.1))
                    .font(.system(size: 20))
            )
    }
    
    private var wordHeaderCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Text(word.wordText)
                    .font(.custom("Marker Felt", size: 38))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                audioButton
            }
            
            HStack(spacing: 20) {
                // Favorite tag
                favoriteButton
                
                // Confidence tag
                confidenceButton
            }
            
            Text("Added on \(word.createdAt.formatted(date: .long, time: .omitted))")
                .font(.custom("Marker Felt", size: 12))
                .foregroundColor(.black.opacity(0.6))
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.black, lineWidth: 2)
                )
        )
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    private var audioButton: some View {
        Group {
            if let audioURL = word.audioURL {
                Button(action: {
                    Task {
                        await playAudio(from: audioURL)
                    }
                }) {
                    if isLoadingAudio {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title2)
                            .foregroundColor(.black)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.9))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: 1.5)
                                    )
                            )
                            .symbolEffect(.bounce, value: isPlaying)
                    }
                }
                .disabled(isLoadingAudio)
            } else {
                EmptyView()
            }
        }
    }
    
    private var favoriteButton: some View {
        HStack(spacing: 5) {
            Image(systemName: word.isFavorite ? "star.fill" : "star")
                .font(.system(size: 14))
                .foregroundColor(word.isFavorite ? .yellow : .black.opacity(0.6))
            Text(word.isFavorite ? "Favorite" : "Not Favorite")
                .font(.custom("Marker Felt", size: 14))
                .foregroundColor(word.isFavorite ? .black : .black.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(word.isFavorite ? Color.yellow.opacity(0.2) : Color.white.opacity(0.6))
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(word.isFavorite ? Color.yellow : Color.black.opacity(0.3), lineWidth: 1.5)
                )
        )
        .onTapGesture {
            withAnimation {
                word.isFavorite.toggle()
                try? modelContext.save()
            }
        }
    }
    
    private var confidenceButton: some View {
        HStack(spacing: 5) {
            Image(systemName: word.isConfident ? "checkmark.seal.fill" : "book.fill")
                .font(.system(size: 14))
                .foregroundColor(word.isConfident ? .green : .orange)
            Text(word.isConfident ? "Confident" : "Learning")
                .font(.custom("Marker Felt", size: 14))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(word.isConfident ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(word.isConfident ? Color.green : Color.orange, lineWidth: 1.5)
                )
        )
        .onTapGesture {
            withAnimation {
                word.isConfident.toggle()
                try? modelContext.save()
            }
        }
    }
    
    private var tabSelectionView: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 6) {
                        Spacer(minLength: 0)
                        
                        Text(tabs[index])
                            .font(.custom("Marker Felt", size: 16))
                            .foregroundColor(selectedTab == index ? .black : .black.opacity(0.6))
                            .padding(.horizontal)
                            .padding(.top, 7)
                        
                        Spacer(minLength: 0)
                        
                        Rectangle()
                            .fill(selectedTab == index ? Color.black : Color.clear)
                            .frame(height: 3)
                    }
                    .frame(height: 44)
                }
                .frame(maxWidth: .infinity)
                .background(selectedTab == index ? Color.white.opacity(0.8) : Color.white.opacity(0.4))
            }
        }
        .background(Color.white.opacity(0.6))
        .overlay(
            Rectangle()
                .fill(Color.black)
                .frame(height: 2),
            alignment: .top
        )
        .padding(.top, 20)
    }
    
    private var tabContentView: some View {
        Group {
            // Word meanings tab
            if selectedTab == 0 {
                if word.meanings.isEmpty {
                    emptyStateView
                } else {
                    meaningsSectionView
                }
            }
            // Notes tab
            else if selectedTab == 1 {
                notesView
            }
            // Fun fact tab
            else if selectedTab == 2 {
                funFactView
            }
            // Linked Items tab
            else if selectedTab == 3 {
                linkedItemsView
            }
        }
    }
    
    private func refreshDetails() async {
        isRefreshingDetails = true
        await WordService.shared.refreshWordDetails(word, modelContext: modelContext)
        isRefreshingDetails = false
    }
    
    // MARK: - Component Views
    
    // Meanings section view
    private var meaningsSectionView: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Spacer()
                
                Button(action: {
                    Task {
                        await refreshDetails()
                    }
                }) {
                    if isRefreshingDetails {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.black)
                    }
                }
                .disabled(isRefreshingDetails)
            }
            
            ForEach(Array(groupedMeanings.keys.sorted()), id: \.self) { partOfSpeech in
                if let meanings = groupedMeanings[partOfSpeech] {
                    VStack(alignment: .leading, spacing: 16) {
                        // Part of speech header
                        HStack {
                            Text(partOfSpeech.capitalized)
                                .font(.custom("Marker Felt", size: 22))
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Text("\(meanings.count) \(meanings.count == 1 ? "meaning" : "meanings")")
                                .font(.custom("Marker Felt", size: 14))
                                .foregroundColor(.black.opacity(0.6))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.brown.opacity(0.2))
                                )
                        }
                        
                        // Meanings
                        ForEach(meanings.indices, id: \.self) { index in
                            meaningCardView(meaning: meanings[index], index: index)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
    }
    
    // Meaning card view
    private func meaningCardView(meaning: Word.WordMeaning, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(index + 1). \(meaning.definition)")
                .font(.custom("Inter-Medium", size: 16))
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
            
            // Example
            if let example = meaning.example {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Example:")
                        .font(.custom("Marker Felt", size: 14))
                        .foregroundColor(.brown)
                    
                    Text("\"\(example)\"")
                        .font(.custom("Inter-Medium", size: 14))
                        .italic()
                        .foregroundColor(.black.opacity(0.7))
                        .padding(.leading, 8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
            }
            
            // Synonyms and Antonyms
            if !meaning.synonyms.isEmpty || !meaning.antonyms.isEmpty {
                // Synonyms
                if !meaning.synonyms.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Synonyms")
                            .font(.custom("Marker Felt", size: 14))
                            .foregroundColor(.brown)
                        
                        FlowLayout(spacing: 4) {
                            ForEach(meaning.synonyms, id: \.self) { synonym in
                                Text(synonym)
                                    .font(.custom("Marker Felt", size: 12))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.green.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 3)
                                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Antonyms
                if !meaning.antonyms.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Antonyms")
                            .font(.custom("Marker Felt", size: 14))
                            .foregroundColor(.brown)
                        
                        FlowLayout(spacing: 4) {
                            ForEach(meaning.antonyms, id: \.self) { antonym in
                                Text(antonym)
                                    .font(.custom("Marker Felt", size: 12))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.red.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 3)
                                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.black, lineWidth: 1)
                )
        )
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                Spacer()
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundColor(.brown)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await refreshDetails()
                    }
                }) {
                    if isRefreshingDetails {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.black)
                    }
                }
                .disabled(isRefreshingDetails)
            }
            
            Text("No definitions available")
                .font(.custom("Marker Felt", size: 18))
                .foregroundColor(.black)
            
            Text("Try checking your internet connection or refreshing.")
                .font(.custom("Marker Felt", size: 16))
                .foregroundColor(.black.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.black, lineWidth: 1)
                )
        )
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
    
    // Notes View
    private var notesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if word.notes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "note.text")
                        .font(.system(size: 50))
                        .foregroundColor(.brown)
                    
                    Text("No notes available")
                        .font(.custom("Marker Felt", size: 18))
                        .foregroundColor(.black)
                    
                    Button(action: { isEditPresented = true }) {
                        Label("Add Notes", systemImage: "square.and.pencil")
                            .font(.custom("Marker Felt", size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.brown)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(Color.black, lineWidth: 1.5)
                                    )
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.black, lineWidth: 1)
                        )
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Personal Notes")
                            .font(.custom("Marker Felt", size: 20))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button(action: { isEditPresented = true }) {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(.black)
                        }
                    }
                    
                    Text(word.notes)
                        .font(.custom("Inter-Regular", size: 16))
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.black, lineWidth: 1)
                        )
                )
                .padding(.bottom, 40)
            }
        }
    }
    
    // Fun Fact View
    private var funFactView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("Fun Fact")
                    .font(.custom("Marker Felt", size: 20))
                    .foregroundColor(.black)
                
                Spacer()
                
                Button(action: {
                    Task {
                        isRefreshingFunFact = true
                        word.funFact = await fetchFunFact(for: word.wordText)
                        try? modelContext.save()
                        isRefreshingFunFact = false
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.black)
                        .rotationEffect(.degrees(isRefreshingFunFact ? 360 : 0))
                        .animation(isRefreshingFunFact ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshingFunFact)
                }
                .disabled(isRefreshingFunFact)
            }
            
            if word.funFact.isEmpty || isRefreshingFunFact {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(isRefreshingFunFact ? "Refreshing fun fact..." : "Loading fun fact...")
                        .font(.custom("Marker Felt", size: 14))
                        .foregroundColor(.black.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                Markdown(word.funFact)
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.black, lineWidth: 1)
                )
        )
    }
    
    private func playAudio(from urlString: String) async {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        isLoadingAudio = true
        
        do {
            // Get audio data from cache or download
            let audioData = try await AudioCache.shared.getAudio(for: urlString)
            
            // Stop any existing audio
            audioPlayer?.stop()
            
            // Play new audio
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            
            // Reset isPlaying when done
            DispatchQueue.main.asyncAfter(deadline: .now() + (audioPlayer?.duration ?? 0)) {
                isPlaying = false
            }
        } catch {
            print("Error playing audio: \(error)")
            errorMessage = "Error playing audio"
        }
        
        isLoadingAudio = false
    }
    
    // Linked Items View
    private var linkedItemsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Linked Words")
                    .font(.custom("Marker Felt", size: 20))
                    .foregroundColor(.black)
                Spacer()
                Button("Manage Links") {
                    isManageLinksPresented = true
                }
                .font(.custom("Marker Felt", size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.blue)
                )
            }
            
            // Filter the queried words to find linked ones
            let linkedWords = allWords.filter { word.linkedItemIDs.contains($0.id) }
            
            if linkedWords.isEmpty {
                Text("No words linked yet.")
                    .font(.custom("Marker Felt", size: 16))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(linkedWords) { linkedWord in
                    Button(action: {
                        // Use the callback to request navigation
                        navigateTo?(linkedWord)
                    }) {
                        HStack {
                            Text(linkedWord.wordText)
                                .font(.custom("Marker Felt", size: 16))
                                .foregroundColor(.black)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain) // Use plain style for list buttons
                }
            }
        }
        .padding()
    }
}

// MARK: - FlowLayout
struct FlowLayout: Layout { // Removed the extra closing brace here
    var alignment: HorizontalAlignment = .leading
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposal: proposal).size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, proposal: ProposedViewSize(width: bounds.width, height: nil)).offsets
        
        for (index, subview) in subviews.enumerated() {
            let origin = CGPoint(x: bounds.minX + offsets[index].x, y: bounds.minY + offsets[index].y)
            subview.place(at: origin, proposal: ProposedViewSize(width: sizes[index].width, height: sizes[index].height))
        }
    }
    
    private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (offsets: [CGPoint], size: CGSize) {
        let width = proposal.width ?? 0
        var offsets = [CGPoint]()
        var currentPosition = CGPoint.zero
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for size in sizes {
            if currentPosition.x + size.width > width && currentPosition.x > 0 {
                currentPosition.x = 0
                currentPosition.y += lineHeight + spacing
                lineHeight = 0
            }
            
            offsets.append(currentPosition)
            currentPosition.x += size.width + spacing
            maxX = max(maxX, currentPosition.x - spacing)
            lineHeight = max(lineHeight, size.height)
        }
        
        return (offsets, CGSize(width: maxX, height: currentPosition.y + lineHeight))
    }
}
