import SwiftUI
import SwiftData
import Foundation
import MarkdownUI

struct PhraseDetailsView: View {
    let phrase: Phrase
    // Removed navigateTo callback
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isEditPresented = false
    @State private var isRefreshingOpinion: Bool = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    
    // Tab titles - Removed "Linked Items"
    private let tabs = ["Notes", "Overlord's Opinion"]
    // Removed isManageLinksPresented state
    
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
                // Phrase card header
                phraseHeaderCard
                
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
                Text("Phrase Details")
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
                            Phrase.delete(phrase, modelContext: modelContext)
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
            ItemFormView(mode: .editPhrase(phrase))
        }
        // Removed sheet for ManageLinksView
        .task {
            if phrase.funOpinion.isEmpty {
                phrase.funOpinion = await fetchFunOpinion(for: phrase.phraseText)
                try? modelContext.save()
            }
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
    
    private var phraseHeaderCard: some View {
        VStack(spacing: 12) {
            Text(phrase.phraseText)
                // Adjust font size based on phrase length
                .font(.custom("Marker Felt", size: phrase.phraseText.count > 50 ? 24 : 30))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true) // Ensure text wraps and isn't cut off
                .padding(.horizontal)
            
            // Favorite tag button
            HStack(spacing: 5) {
                Image(systemName: phrase.isFavorite ? "star.fill" : "star")
                    .font(.system(size: 14))
                    .foregroundColor(phrase.isFavorite ? .yellow : .black.opacity(0.6))
                Text(phrase.isFavorite ? "Favorite" : "Not Favorite")
                    .font(.custom("Marker Felt", size: 14))
                    .foregroundColor(phrase.isFavorite ? .black : .black.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(phrase.isFavorite ? Color.yellow.opacity(0.2) : Color.white.opacity(0.6))
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(phrase.isFavorite ? Color.yellow : Color.black.opacity(0.3), lineWidth: 1.5)
                    )
            )
            .onTapGesture {
                withAnimation {
                    phrase.isFavorite.toggle()
                    try? modelContext.save()
                }
            }
            
            Text("Added on \(phrase.createdAt.formatted(date: .long, time: .omitted))")
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
            // Notes tab
            if selectedTab == 0 {
                notesView
            }
            // Overlord's Opinion tab
            else if selectedTab == 1 {
                opinionView
            }
            // Removed Linked Items tab case
        }
    }
    
    // MARK: - Component Views
    
    // Notes View
    private var notesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if phrase.notes.isEmpty {
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
                        Image(systemName: "note.text")
                            .foregroundColor(.brown)
                        
                        Text("Personal Notes")
                            .font(.custom("Marker Felt", size: 20))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button(action: { isEditPresented = true }) {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(.black)
                        }
                    }
                    
                    Text(phrase.notes)
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
    
    // Overlord's Opinion View
    private var opinionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.purple)
                
                Text("Locker Overlord's Opinion")
                    .font(.custom("Marker Felt", size: 20))
                    .foregroundColor(.black)
                
                Spacer()
                
                Button(action: {
                    Task {
                        isRefreshingOpinion = true
                        phrase.funOpinion = await fetchFunOpinion(for: phrase.phraseText)
                        try? modelContext.save()
                        isRefreshingOpinion = false
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.black)
                        .rotationEffect(.degrees(isRefreshingOpinion ? 360 : 0))
                        .animation(isRefreshingOpinion ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshingOpinion)
                }
                .disabled(isRefreshingOpinion)
            }
            
            if phrase.funOpinion.isEmpty || isRefreshingOpinion {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(isRefreshingOpinion ? "The Overlord is contemplating..." : "Awaiting the Overlord's wisdom...")
                        .font(.custom("Marker Felt", size: 14))
                        .foregroundColor(.black.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                Markdown(phrase.funOpinion)
                    .font(.custom("Marker Felt", size: 16))
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
    // Removed linkedItemsView
}
