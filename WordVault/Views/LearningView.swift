import SwiftUI
import SwiftData

struct LearningView: View {    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color matching the app
                Color(red: 0.86, green: 0.75, blue: 0.6)
                    .ignoresSafeArea()
                    .overlay(
                        Image(systemName: "circle.grid.cross.fill")
                            .foregroundColor(.brown.opacity(0.1))
                            .font(.system(size: 20))
                    )
                
                List {
                    ForEach(LearningMode.allCases, id: \.self) { mode in
                        NavigationLink(destination: modeView(for: mode)) {
                            HStack {
                                Image(systemName: mode.icon)
                                    .foregroundColor(.brown)
                                    .font(.title2)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading) {
                                    Text(mode.rawValue)
                                        .font(.custom("Marker Felt", size: 20))
                                        .foregroundColor(.black)
                                    Text(mode.description)
                                        .font(.custom("Marker Felt", size: 14))
                                        .foregroundColor(.black.opacity(0.5))
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listRowBackground(Color.white.opacity(0.7))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Learning Modes")
                        .font(.custom("Marker Felt", size: 20))
                        .foregroundColor(.black)
                }
            }
        }
    }
    
    @ViewBuilder
    private func modeView(for mode: LearningMode) -> some View {
        switch mode {
        case .wordDefinitionWriting:
            WordDefinitionWritingView()
        case .wordUsage:
            WordUsageView()
        }
    }
} 
