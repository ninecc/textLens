import CryptoKit
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class FreeTranslationService {
    public struct Config {
        public let provider: FreeTranslationProvider
        public let youdaoAppID: String
        public let youdaoSecret: String
        public let baiduAppID: String
        public let baiduSecret: String

        public init(
            provider: FreeTranslationProvider,
            youdaoAppID: String = "",
            youdaoSecret: String = "",
            baiduAppID: String = "",
            baiduSecret: String = ""
        ) {
            self.provider = provider
            self.youdaoAppID = youdaoAppID
            self.youdaoSecret = youdaoSecret
            self.baiduAppID = baiduAppID
            self.baiduSecret = baiduSecret
        }
    }

    public enum Error: LocalizedError, Equatable {
        case missingCredentials(String)
        case api(String)
        case malformedResponse

        public var errorDescription: String? {
            switch self {
            case .missingCredentials(let provider): return "\(provider) credentials are missing."
            case .api(let message): return message
            case .malformedResponse: return "Free translation response was not readable."
            }
        }
    }

    private let session: URLSession
    private let nonce: () -> String
    private let timestamp: () -> Int

    public init(
        session: URLSession = .shared,
        nonce: @escaping () -> String = { UUID().uuidString },
        timestamp: @escaping () -> Int = { Int(Date().timeIntervalSince1970) }
    ) {
        self.session = session
        self.nonce = nonce
        self.timestamp = timestamp
    }

    public func translate(text: String, targetLanguage: String, config: Config) async throws -> String {
        switch config.provider {
        case .google:
            return try await google(text: text, targetLanguage: targetLanguage)
        case .myMemory:
            return try await myMemory(text: text, targetLanguage: targetLanguage)
        case .youdao:
            return try await youdao(text: text, targetLanguage: targetLanguage, appID: config.youdaoAppID, secret: config.youdaoSecret)
        case .baidu:
            return try await baidu(text: text, targetLanguage: targetLanguage, appID: config.baiduAppID, secret: config.baiduSecret)
        }
    }

    private func google(text: String, targetLanguage: String) async throws -> String {
        var components = URLComponents(string: "https://translate.googleapis.com/translate_a/single")!
        components.queryItems = [
            .init(name: "client", value: "gtx"),
            .init(name: "sl", value: "auto"),
            .init(name: "tl", value: googleCode(for: targetLanguage)),
            .init(name: "dt", value: "t"),
            .init(name: "q", value: text)
        ]

        let data = try await data(from: components.url!)
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let sentences = root.first as? [Any] else {
            throw Error.malformedResponse
        }

        return try joined(sentences.compactMap { ($0 as? [Any])?.first as? String })
    }

    private func myMemory(text: String, targetLanguage: String) async throws -> String {
        var components = URLComponents(string: "https://api.mymemory.translated.net/get")!
        components.queryItems = [
            .init(name: "q", value: text),
            .init(name: "langpair", value: "en|\(myMemoryCode(for: targetLanguage))")
        ]

        let data = try await data(from: components.url!)
        guard let root = try? JSONDecoder().decode(MyMemoryResponse.self, from: data) else {
            throw Error.malformedResponse
        }
        return try joined([root.responseData.translatedText])
    }

    private func youdao(text: String, targetLanguage: String, appID: String, secret: String) async throws -> String {
        guard !appID.isEmpty, !secret.isEmpty else {
            throw Error.missingCredentials("Youdao")
        }

        let salt = nonce()
        let curtime = String(timestamp())
        var components = URLComponents(string: "https://openapi.youdao.com/api")!
        components.queryItems = [
            .init(name: "q", value: text),
            .init(name: "from", value: "auto"),
            .init(name: "to", value: youdaoCode(for: targetLanguage)),
            .init(name: "appKey", value: appID),
            .init(name: "salt", value: salt),
            .init(name: "sign", value: sha256(appID + youdaoInput(text) + salt + curtime + secret)),
            .init(name: "signType", value: "v3"),
            .init(name: "curtime", value: curtime)
        ]

        let data = try await data(from: components.url!)
        guard let root = try? JSONDecoder().decode(YoudaoResponse.self, from: data),
              root.errorCode == "0",
              let translation = root.translation else {
            throw Error.malformedResponse
        }
        return try joined(translation)
    }

    private func baidu(text: String, targetLanguage: String, appID: String, secret: String) async throws -> String {
        guard !appID.isEmpty, !secret.isEmpty else {
            throw Error.missingCredentials("Baidu")
        }

        let salt = nonce()
        var components = URLComponents(string: "https://fanyi-api.baidu.com/api/trans/vip/translate")!
        components.queryItems = [
            .init(name: "q", value: text),
            .init(name: "from", value: "auto"),
            .init(name: "to", value: baiduCode(for: targetLanguage)),
            .init(name: "appid", value: appID),
            .init(name: "salt", value: salt),
            .init(name: "sign", value: md5(appID + text + salt + secret))
        ]

        let data = try await data(from: components.url!)
        guard let root = try? JSONDecoder().decode(BaiduResponse.self, from: data),
              root.errorCode == nil,
              let result = root.transResult else {
            throw Error.malformedResponse
        }
        return try joined(result.map(\.dst))
    }

    private func data(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw Error.api("Free translation failed with status \(status).")
        }
        return data
    }

    private func joined(_ parts: [String]) throws -> String {
        let output = parts.joined().trimmingCharacters(in: .whitespacesAndNewlines)
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

    private func myMemoryCode(for targetLanguage: String) -> String { googleCode(for: targetLanguage) }

    private func youdaoCode(for targetLanguage: String) -> String {
        switch SupportedLanguage.normalized(targetLanguage).name {
        case "Arabic": return "ar"
        case "English": return "en"
        case "French": return "fr"
        case "Russian": return "ru"
        case "Spanish": return "es"
        default: return "zh-CHS"
        }
    }

    private func baiduCode(for targetLanguage: String) -> String {
        switch SupportedLanguage.normalized(targetLanguage).name {
        case "Arabic": return "ara"
        case "English": return "en"
        case "French": return "fra"
        case "Russian": return "ru"
        case "Spanish": return "spa"
        default: return "zh"
        }
    }

    private func youdaoInput(_ text: String) -> String {
        guard text.count > 20 else { return text }
        return "\(text.prefix(10))\(text.count)\(text.suffix(10))"
    }

    private func sha256(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private func md5(_ text: String) -> String {
        Insecure.MD5.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

private struct MyMemoryResponse: Decodable {
    let responseData: ResponseData

    struct ResponseData: Decodable {
        let translatedText: String
    }
}

private struct YoudaoResponse: Decodable {
    let errorCode: String
    let translation: [String]?
}

private struct BaiduResponse: Decodable {
    let errorCode: String?
    let transResult: [Result]?

    private enum CodingKeys: String, CodingKey {
        case errorCode = "error_code"
        case transResult = "trans_result"
    }

    struct Result: Decodable {
        let dst: String
    }
}
