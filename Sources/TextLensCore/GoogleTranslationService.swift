import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class GoogleTranslationService {
    public enum Error: LocalizedError, Equatable {
        case api(String)
        case malformedResponse

        public var errorDescription: String? {
            switch self {
            case .api(let message): return message
            case .malformedResponse: return "Free translation response was not readable."
            }
        }
    }

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func translate(text: String, targetLanguage: String) async throws -> String {
        var components = URLComponents(string: "https://translate.googleapis.com/translate_a/single")!
        components.queryItems = [
            .init(name: "client", value: "gtx"),
            .init(name: "sl", value: "auto"),
            .init(name: "tl", value: googleCode(for: targetLanguage)),
            .init(name: "dt", value: "t"),
            .init(name: "q", value: text)
        ]

        let (data, response) = try await session.data(from: components.url!)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw Error.api("Free translation failed with status \(status).")
        }

        guard let root = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let sentences = root.first as? [Any] else {
            throw Error.malformedResponse
        }

        let output = sentences.compactMap { sentence -> String? in
            (sentence as? [Any])?.first as? String
        }.joined().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !output.isEmpty else { throw Error.malformedResponse }
        return output
    }

    private func googleCode(for targetLanguage: String) -> String {
        switch SupportedLanguage.normalized(targetLanguage).name {
        case "Arabic": return "ar"
        case "English": return "en"
        case "French": return "fr"
        case "Russian": return "ru"
        case "Spanish": return "es"
        default: return "zh-CN"
        }
    }
}
