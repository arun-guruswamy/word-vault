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
        As a witty and knowledgeable language expert, share a truly unexpected and surprising fun fact about the word "\(word)". 
        AVOID discussing etymology or Latin/Greek origins unless it's genuinely fascinating.
        Instead, focus on one of these types of facts:
        1. Bizarre historical usage or events connected to the word
        2. Unexpected pop culture references or appearances
        3. Strange scientific connections or applications
        4. Quirky statistics or record-breaking instances
        5. Unusual laws or regulations involving the word
        6. Surprising cultural differences in how the word is perceived
        
        Make it sound like "Wow, I never knew that about this word!"
        Keep it concise (2-3 sentences), engaging, and genuinely surprising.
        Add a touch of humor if appropriate.
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
        Share your perspective on the phrase "\(phrase)".
        If the phrase is interesting, share an unexpected insight or a thought-provoking observation.
        If the phrase is a popular quote referenced from somew media or person then point out its origin.
        If the phrase is mundane or unclear, respond with playful sarcasm or mockery.
        Keep it concise but entertaining.
        """
        let response = try await chat.sendMessage(message)
        return response.text ?? "No response received"
    } catch {
        print(error)
        return "The Vault Overlord is currently preoccupied with more important matters."
    }
}
