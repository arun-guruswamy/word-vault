import GoogleGenerativeAI
import Foundation

let config = GenerationConfig(
  temperature: 1,
  topP: 0.95,
  topK: 40,
  maxOutputTokens: 8192,
  responseMIMEType: "text/plain"
)

let apiKey = ProcessInfo.processInfo.environment["API_KEY"] ?? ""

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
        let message = """
        As a witty and knowledgeable language expert, share a fascinating fact about the word "\(word)". 
        Make it entertaining and memorable, like a fun party fact. 
        Include unexpected connections, historical tidbits, or cultural significance.
        Keep it concise but engaging, and add a touch of humor if appropriate.
        """
        let response = try await chat.sendMessage(message)
        return response.text ?? "No response received"
    } catch {
        print(error)
        return "Could not fetch a fun fact."
    }
}

func fetchFunOpinion(for phrase: String) async -> String {
    do {
        let message = """
        As the mysterious Vault Overlord, share your unique perspective on the phrase "\(phrase)".
        Be dramatic, witty, and slightly theatrical in your response.
        If the phrase is interesting, share an unexpected insight or a thought-provoking observation.
        If the phrase is mundane or unclear, respond with playful sarcasm or mockery.
        Keep it concise but entertaining, and maintain your overlord persona throughout.
        """
        let response = try await chat.sendMessage(message)
        return response.text ?? "No response received"
    } catch {
        print(error)
        return "The Overlord is currently preoccupied with more important matters."
    }
}
