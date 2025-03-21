import GoogleGenerativeAI

let config = GenerationConfig(
  temperature: 1,
  topP: 0.95,
  topK: 40,
  maxOutputTokens: 8192,
  responseMIMEType: "text/plain"
)

// Don't check your API key into source control!
// guard let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] else {
//   fatalError("Add GEMINI_API_KEY as an Environment Variable in your app's scheme.")
// }
let apiKey = ""

let model = GenerativeModel(
  name: "gemini-2.0-flash",
  apiKey: apiKey,
  generationConfig: config
)

let chat = model.startChat(history: [
//   ModelContent(
//     role: "user",
//     parts: [
//       .text("Can you provide a fun bit of information about <insert word here>")
//     ]
//   )
])

func fetchFunFact(for word: String) async -> String {
    do {
        let message = "Can you provide a fun bit of information about \(word)?"
        let response = try await chat.sendMessage(message)
        return response.text ?? "No response received"
    } catch {
        print(error)
        return "Error fetching fun fact."
    }
}
