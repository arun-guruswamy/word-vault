import SwiftUI
import SwiftData

struct LearningView: View {    
    var body: some View {
        NavigationView {
            List {
                ForEach(LearningMode.allCases, id: \.self) { mode in
                    NavigationLink(destination: modeView(for: mode)) {
                        HStack {
                            Image(systemName: mode.icon)
                                .foregroundColor(.blue)
                                .font(.title2)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text(mode.rawValue)
                                    .font(.headline)
                                Text(mode.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Learning Modes")
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
