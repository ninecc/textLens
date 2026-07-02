import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class TranslationService {
    public struct Config {
        public let baseURL: URL
        public let apiKey: String
        public let model: String

        public init(baseURL: URL, apiKey: String, model: String) {
            self.baseURL = baseURL
            self.apiKey = apiKey
            self.model = model
        }
    }

    public enum Error: LocalizedError, Equatable {
        case api(String)
        case malformedResponse

        public var errorDescription: String? {
            switch self {
            case .api(let message): return message
            case .malformedResponse: return "Translation response was not readable."
            }
        }
    }

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func translate(text: String, targetLanguage: String, config: Config) async throws -> String {
        var request = URLRequest(url: config.baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(ChatRequest(
            model: config.model,
            messages: [
                .init(role: "system", content: "Translate the user's text into \(targetLanguage). Return only the translation."),
                .init(role: "user", content: text)
            ]
        ))

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        if !(200..<300).contains(status) {
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw Error.api(apiError.error.message)
            }
            throw Error.api("Translation request failed with status \(status).")
        }

        guard let output = try? JSONDecoder().decode(ChatResponse.self, from: data),
              let content = output.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else {
            throw Error.malformedResponse
        }

        return content
    }
}

private struct ChatRequest: Encodable {
    let model: String
    let messages: [Message]

    struct Message: Encodable {
        let role: String
        let content: String
    }
}

private struct ChatResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String
    }
}

private struct APIErrorResponse: Decodable {
    let error: APIError

    struct APIError: Decodable {
        let message: String
    }
}
