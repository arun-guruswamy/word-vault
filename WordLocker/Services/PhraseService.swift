import Foundation
import SwiftData

class PhraseService {
    static let shared = PhraseService()
    
    private init() {}
    
    func createPhrase(text: String, notes: String = "", isFavorite: Bool = false, 
                     collectionNames: [String] = []) -> Phrase {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let phrase = Phrase(phraseText: trimmedText)
        phrase.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        phrase.isFavorite = isFavorite
        phrase.collectionNames = collectionNames
        
        return phrase
    }
    
    // Removed populatePhraseContent as its logic is integrated below

    @MainActor
    func savePhrase(_ phrase: Phrase, modelContext: ModelContext) { // No longer needs async
        // Save the initial phrase or update existing properties on the MainActor
        // Assuming Phrase.save handles insertion/initial save
        Phrase.save(phrase, modelContext: modelContext)

        // --- Easter Egg Trigger ---
        // Check if the magic phrase was added and if the secret collections haven't been added yet
        if phrase.phraseText.lowercased() == "win win aung".lowercased() && !UserDefaults.standard.bool(forKey: "winWinAungSecretAdded") {
            print("PhraseService: Magic phrase 'Win Win Aung' detected! Adding predefined collections.")
            self.addPredefinedCollections(modelContext: modelContext)
        }
        // --- End Easter Egg Trigger ---

        // Launch a task on the MainActor to fetch and update the fun opinion
        Task {
            // Fetch opinion asynchronously (can switch threads internally)
            // Assuming fetchFunOpinion exists and returns String
            let funOpinion = await fetchFunOpinion(for: phrase.phraseText)
            
            // Update the phrase (still on MainActor)
            // Check if the phrase object is still valid in the context by fetching it
            let phraseID = phrase.id // Capture the ID locally
            let fetchDescriptor = FetchDescriptor<Phrase>(predicate: #Predicate { $0.id == phraseID })
            if let fetchedPhrase = try? modelContext.fetch(fetchDescriptor).first {
                 // Phrase exists in context, update it
                 fetchedPhrase.funOpinion = funOpinion
                 // Save the updated phrase context
                 do {
                     try modelContext.save()
                 } catch {
                     // Handle or log the save error appropriately
                     print("Error saving phrase after updating fun opinion: \(error)")
                 }
            } else {
                 print("Phrase \(phrase.id) no longer in context, skipping funOpinion update.")
            }
        }
    }
    
    // Assume fetchFunOpinion is defined elsewhere, e.g.:
    // func fetchFunOpinion(for text: String) async -> String { ... }

    // MARK: - Easter Egg Function
    
    @MainActor
    private func addPredefinedCollections(modelContext: ModelContext) {
        let collection1Name = "Crossword chronicles"
        let collection2Name = "The holy house laws"
        let collection3Name = "The best qualities you May have"
        let collectionNames = [collection1Name, collection2Name, collection3Name]
        let hiddenTag = "_predefined_secret_" // Define the hidden tag

        // --- Ensure Collection Objects Exist ---
        for name in collectionNames {
            // Check if collection already exists
            let fetchDescriptor = FetchDescriptor<Collection>(predicate: #Predicate { $0.name == name })
            do {
                let existingCollections = try modelContext.fetch(fetchDescriptor)
                if existingCollections.isEmpty {
                    // Create and insert if it doesn't exist
                    let newCollection = Collection(name: name)
                    modelContext.insert(newCollection)
                    print("PhraseService: Created Collection object for '\(name)'")
                } else {
                    print("PhraseService: Collection object for '\(name)' already exists.")
                }
            } catch {
                print("PhraseService: Error checking for existing collection '\(name)': \(error)")
                // Decide if we should proceed or stop if check fails
            }
        }
        // It's generally safe to proceed even if the check fails,
        // as saving later might just update existing words/phrases if they were somehow added before.

        // --- Collection 1 Data ---
        let crosswordItems: [(String, String, Bool)] = [ // (Text, Notes, isWord)
            ("Fresh", "Sassy. \"Don't get fresh with me,\" meaning \"Don't be rude or disrespectful to me\".", true),
            ("Raunchy", "earthy, vulgar, and often sexually explicit", true),
            ("Ere", "archaic or poetic way of saying \"before”", true),
            ("Blue holes", "massive underwater sinkholes or caverns found in oceans and coastal regions", false),
            ("Eon", "equivalent of a billion years", true),
            ("Serf", "feudal worker", true),
            ("Mao Zhedong", "Leader and founding member of Chinese Communist Party; The Great Leap Forward was an attempt to rapidly industrialize China; The Cultural Revolution was a campaign to reassert Mao’s power and eliminate \"bourgeois\" influences", false),
            ("Tress", "a long lock or curl of hair", true),
            ("Walrus moustache", "characterized by whiskers that are thick, bushy, and drop over the mouth (Mark Twain and Theodore Roosevelt had this)", false),
            ("Mug", "make faces, especially silly or exaggerated ones, before an audience or a camera", true),
            ("Koko the Gorilla", "learned sign language at the SF Zoo", false),
            ("U-bolts", "U-shaped fasteners with threaded ends, commonly used to secure pipes, tubes, or other cylindrical objects to surfaces or structures", false),
            ("Bilge pump", "Used to remove water from a boat", false),
            ("Ich bin ein berliner", "\"Ich bin ein Berliner\" is a speech by United States President John F. Kennedy given on June 26, 1963, in West Berlin. It is one of the best-known speeches of the Cold War and among the most famous anti-communist speeches.", false),
            ("Tickle the ivories", "colloquial expression that means to play the piano", false),
            ("Tenon and Mortise", "A common woodworking joint.", false), // Added placeholder note
            ("Beethoven’s Symphonies", "Includes No. 1 in C, No. 2 in D, No. 3 'Eroica', No. 4 in B flat, No. 5 in C minor, No. 6 'Pastoral', No. 7 in A, No. 8 in F.", false), // Summarized notes
            ("Rapini", "broccoli rabe or raab) is a green cruciferous vegetable", true),
            ("Awl", "A pointed tool for making holes, typically in wood or leather.", true), // Added placeholder note
            ("Lao", "is a similar language to Thai", true),
            ("Hoi Polloi", "\"Hoi polloi\" is a Greek phrase meaning \"the many\" or \"the common people,\" often used in a derogatory way to refer to the masses or the working class", false),
            ("Tuba", "is an wind instrument that has bells in it", true),
            ("Great lakes", "HOMES (Huron, Ontario, Michigan, Erie, Superior)", false),
            ("Hawkish", "advocating an aggressive or warlike policy, especially in foreign affairs.", true),
            ("Twee", "excessively or affectedly quaint, pretty, or sentimental. \"although the film's a bit twee, it's watchable\"", true),
            ("Aral Sea", "Once the 4th largest sea in the world.", false), // Added placeholder note
            ("Sea of Tranquility", "The \"Sea of Tranquility,\" or Mare Tranquillitatis, is a lunar mare (a large, dark, flat area on the moon) located within the Tranquillitatis basin, and it's the site of the first manned lunar landing, where Apollo 11 touched down in 1969", false),
            ("Passover", "or Pesach in Hebrew, is a Jewish holiday that celebrates the liberation of the Israelites from slavery in Egypt, celebrated in April", true),
            ("Seussian", "especially in being whimsical or fantastical, in writing, like Dr Seuss", true),
            ("squirreled capital", "refers to money or resources that are hidden away or saved secretly, much like how a squirrel stores away nuts for the winter in hidden places.", false),
            ("Decon", "is an abbreviation for decontamination", true),
            ("Taser", "was initially “TASER,” abbreviating “Thomas A. Swift Electric Rifle”", true),
            ("Gesundheit", "used to wish good health to a person who has just sneezed.", true),
            ("Morsel", "a small piece or amount of food; a mouthful. Julie pushed a last morsel of toast into her mouth", true),
            ("Etta James", "Matriarch of R&B music", false),
            ("Sushi eggs", "Roe", false),
            ("Fray", "Unravel around the edges. the frayed collar of her old coat", true),
            ("Rasta", "a term that can refer to Rastafarianism, a religion and cultural movement that originated in Jamaica. Rastafari believe in a single God, Jah, who is immanent within each person", true),
            ("Semi Truck", "has 18 wheels", false),
            ("Salli Mae", "federal student loan agency", false),
            ("UK Military Branch with jets", "RAF (Royal Air Force)", false),
            ("En Garde", "The referee says \"en garde\" before the start of a fencing bout to signal the fencers to get into position", false),
            ("Epee", "Fencing blade", true),
            ("Line up the side of a dress", "Seam", false),
            ("Museum with paintings by Goya and Bosch", "Prado", false)
        ]

        // --- Collection 2 Data ---
        let houseLaws: [(String, String)] = [
            ("Keep the bathroom door closed", "In case the bathroom demons sneak in."),
            ("Shut the toilet seat down", "So it’s ready to be sit on while brushing."),
            ("Turn off ALL electronics in the house, even the tiniest LED", "In case there’s an apocalypse of course."),
            ("Leave no dishes behind in the kitchen sink", "No one wants to attract them roaches."),
            ("MOST IMPORTANTLY, make sure the faucet filter is turned off while filling water", "Don’t ask why, just do it."),
            ("Do not wear outside clothes on the bed", "What more is there to be said."),
            ("Do not leave ANY electronics on the bed", "The radiation could turn you into the Hulk in your sleep."),
            ("When you have your shoes on, do not take more steps in the house than a basketball player could with a ball", "House would have to undergo decontamination otherwise.")
        ]

        // --- Collection 3 Data ---
        let bestQualities: [String] = [
            "Down to Earth", "Compassionate", "Smart", "Hard-Working",
            "Good Listener", "Enthusiastic", "Beaming smile", "Athletic"
        ]

        // --- Create and Insert Objects ---
        Task { // Perform creation potentially off main thread if Word/Phrase init allows
            // Collection 1
            for item in crosswordItems {
                if item.2 { // isWord
                    let word = await Word(wordText: item.0) // Assuming Word init might be async
                    word.notes = item.1
                    word.collectionNames = [collection1Name, hiddenTag] // Add hidden tag
                    modelContext.insert(word)
                } else { // isPhrase
                    let phrase = Phrase(phraseText: item.0)
                    phrase.notes = item.1
                    phrase.collectionNames = [collection1Name, hiddenTag] // Add hidden tag
                    modelContext.insert(phrase)
                }
            }

            // Collection 2
            for item in houseLaws {
                let phrase = Phrase(phraseText: item.0)
                phrase.notes = item.1
                phrase.collectionNames = [collection2Name, hiddenTag] // Add hidden tag
                modelContext.insert(phrase)
            }

            // Collection 3
            for item in bestQualities {
                let phrase = Phrase(phraseText: item)
                phrase.notes = "" // No notes for this collection
                phrase.collectionNames = [collection3Name, hiddenTag] // Add hidden tag
                modelContext.insert(phrase)
            }

            // --- Save and Set Flag ---
            do {
                try modelContext.save()
                UserDefaults.standard.set(true, forKey: "winWinAungSecretAdded")
                print("PhraseService: Successfully added predefined collections and set flag.")
            } catch {
                print("PhraseService: Error saving predefined collections: \(error)")
                // Optionally: Decide if you want to rollback or handle partial saves.
                // For an Easter egg, maybe just logging the error is sufficient.
            }
        }
    }
}
