import SwiftUI
import SwiftData
import Foundation
import MarkdownUI
import AVFoundation

struct WordDetailsView: View {
    let word: Word
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isEditPresented = false
    @State private var isRefreshingFunFact: Bool = false
    @State private var errorMessage: String?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying: Bool = false
    @State private var isLoadingAudio: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text(word.wordText)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
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
                                        .foregroundColor(.blue)
                                        .symbolEffect(.bounce, value: isPlaying)
                                }
                            }
                            .disabled(isLoadingAudio)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("Added on \(word.createdAt.formatted(date: .long, time: .shortened))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 15)
                    
                    if word.meanings.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            VStack(spacing: 4) {
                                Text("No information found")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(word.meanings, id: \.partOfSpeech) { meaning in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(meaning.partOfSpeech.capitalized)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                
                                ForEach(meaning.definitions.indices, id: \.self) { index in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("\(index + 1). \(meaning.definitions[index].definition)")
                                            .font(.body)
                                        
                                        if let example = meaning.definitions[index].example {
                                            Text("Example: \(example)")
                                                .font(.body)
                                                .italic()
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.bottom, 8)
                                }
                            }
                            .padding(.bottom, 16)
                        }
                    }
                    
                    if !word.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Personal Notes")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text(word.notes)
                                .font(.body)
                        }
                        .padding(.top, 8)
                    }
                    
                    if !word.meanings.isEmpty {
                        HStack {
                            Text("Fun Fact")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
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
                                    .foregroundColor(.blue)
                                    .rotationEffect(.degrees(isRefreshingFunFact ? 360 : 0))
                                    .animation(isRefreshingFunFact ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshingFunFact)
                            }
                        }
                        
                        if word.funFact.isEmpty || isRefreshingFunFact {
                            ProgressView(isRefreshingFunFact ? "Refreshing fun fact..." : "Loading fun fact...")
                        } else {
                            Markdown("\(word.funFact)")
                                .font(.body)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarItems(
                leading: Button("Done") {
                    dismiss()
                },
                trailing: HStack {
                    Button(action: {
                        word.isFavorite.toggle()
                        try? modelContext.save()
                    }) {
                        Image(systemName: word.isFavorite ? "star.fill" : "star")
                            .foregroundColor(word.isFavorite ? .yellow : .gray)
                    }
                    
                    Button(action: { isEditPresented = true }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        Word.delete(word, modelContext: modelContext)
                        dismiss()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            )
            .sheet(isPresented: $isEditPresented) {
                ItemFormView(mode: .editWord(word))
            }
            .padding(.trailing, 12.5)
            .padding(.leading, 12.5)
            .onDisappear {
                audioPlayer?.stop()
            }
        }
    }
    
    private func playAudio(from urlString: String) async {
        isLoadingAudio = true
        do {
            let audioData = try await AudioCache.shared.getAudio(for: urlString)
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = AudioPlayerDelegate(isPlaying: $isPlaying)
            isPlaying = true
            audioPlayer?.play()
        } catch {
            print("Error playing audio: \(error)")
            errorMessage = "Failed to play audio"
            isPlaying = false
        }
        isLoadingAudio = false
    }
}

class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    @Binding var isPlaying: Bool
    
    init(isPlaying: Binding<Bool>) {
        _isPlaying = isPlaying
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}
