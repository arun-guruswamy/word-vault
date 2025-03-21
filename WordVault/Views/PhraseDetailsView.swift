import SwiftUI
import SwiftData
import Foundation

struct PhraseDetailsView: View {
    let phrase: Phrase
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isEditPresented = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(phrase.phraseText)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("Added on \(phrase.createdAt.formatted(date: .long, time: .shortened))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 15)
                    
                    if !phrase.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Personal Notes")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text(phrase.notes)
                                .font(.body)
                        }
                        .padding(.top, 8)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "note.text")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No notes added")
                                .font(.title3)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        Button(action: {
                            phrase.isFavorite.toggle()
                            try? modelContext.save()
                        }) {
                            Image(systemName: phrase.isFavorite ? "star.fill" : "star")
                                .foregroundColor(phrase.isFavorite ? .yellow : .gray)
                        }
                        
                        Button(action: { isEditPresented = true }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            Phrase.delete(phrase, modelContext: modelContext)
                            dismiss()
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
        }
    }
} 
