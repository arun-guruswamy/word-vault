import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: StatsViewModel
    
    // Initialize with a temporary context, will be replaced onAppear
    init() {
        let tempContext = try! ModelContext(ModelContainer(for: Word.self, Phrase.self))
        _viewModel = State(initialValue: StatsViewModel(modelContext: tempContext))
    }
    
    var body: some View {
        ZStack { // Add ZStack for background
            // Cork board background
            Color(red: 0.86, green: 0.75, blue: 0.6)
                .ignoresSafeArea()
                .overlay(
                    Image(systemName: "circle.grid.cross.fill")
                        .foregroundColor(.brown.opacity(0.1))
                        .font(.system(size: 20))
                )
            
            // ScrollView contains the content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // MARK: - Totals Section (Improved UI)
                    // Remove GroupBox, style HStack directly
                    HStack(spacing: 20) { // Add spacing between items
                        VStack(alignment: .center) { // Center align text
                            Text("Words")
                                .font(.headline)
                                .foregroundColor(.black.opacity(0.7)) // Slightly muted color
                            Text("\(viewModel.totalWordCount)")
                                .font(.system(size: 40, weight: .bold, design: .rounded)) // Larger, rounded font
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity) // Make VStacks take equal width
                        
                        Divider().frame(height: 50) // Add a visual separator
                        
                        VStack(alignment: .center) { // Center align text
                            Text("Phrases")
                                .font(.headline)
                                .foregroundColor(.black.opacity(0.7)) // Slightly muted color
                            Text("\(viewModel.totalPhraseCount)")
                                .font(.system(size: 40, weight: .bold, design: .rounded)) // Larger, rounded font
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity) // Make VStacks take equal width
                    }
                    .padding() // Add padding inside the card
                    .background(Color.white) // Light yellow background like a note
                    .cornerRadius(10) // Rounded corners
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 2, y: 2) // Subtle shadow
                    .overlay( // Add a subtle border
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
                    
                    
                    // MARK: - Word Confidence Section
                    GroupBox("Word Confidence") {
                        if !viewModel.wordConfidenceStats.isEmpty {
                            Chart(viewModel.wordConfidenceStats) { stat in
                                SectorMark(
                                    angle: .value("Count", stat.count),
                                    innerRadius: .ratio(0.618),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(by: .value("Category", stat.category)) // Use default colors
                                .annotation(position: .overlay) {
                                    Text("\(stat.count)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                    // Let SwiftUI handle text color contrast
                                }
                                .cornerRadius(5)
                            }
                        .frame(height: 200)
                        .chartLegend(position: .bottom, alignment: .center)
                        .chartForegroundStyleScale([ // Add custom colors
                            "Learning": Color.orange,
                            "Confident": Color.green
                        ])
                    } else {
                        ContentUnavailableView("No Word Data", systemImage: "chart.pie", description: Text("Add some words to see confidence stats."))
                                .frame(height: 200)
                        }
                    }
                    
                    // MARK: - Word Length Distribution Section
                    GroupBox("Word Length Distribution") { // Changed title
                        // Removed Picker
                        
                        if !viewModel.wordLengthStats.isEmpty { // Use wordLengthStats
                            Chart(viewModel.wordLengthStats) { stat in // Use WordLengthStat
                                SectorMark( // Use SectorMark for pie chart
                                    angle: .value("Count", stat.count),
                                    innerRadius: .ratio(0.618), // Donut chart style
                                    angularInset: 1.5
                                )
                                .foregroundStyle(by: .value("Length", stat.lengthCategory)) // Color by length category
                                .annotation(position: .overlay) {
                                    Text("\(stat.count)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white) // Use white for contrast on segments
                                }
                                .cornerRadius(5)
                            }
                            // Use default colors or add a specific scale if desired
                            .chartLegend(position: .bottom, alignment: .center)
                            .frame(height: 250) // Keep or adjust height
                        } else {
                            // Updated ContentUnavailableView
                            ContentUnavailableView("No Word Data", systemImage: "chart.pie", description: Text("Add some words to see length stats."))
                                .frame(height: 250)
                        }
                    }
                }
                .padding() // Add padding around the VStack
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline) // Keep title inline
            // Removed custom toolbar background and font
            .onAppear {
                // Use the environment's model context when the view appears
                viewModel = StatsViewModel(modelContext: modelContext)
            }
            // Removed custom accentColor
        }
    }
}
