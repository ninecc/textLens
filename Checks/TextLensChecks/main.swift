import Foundation
import TextLensCore

final class TestURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

func testSettingsDefaults() {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    let store = SettingsStore(defaults: defaults)

    check(store.baseURL == URL(string: "https://api.openai.com/v1/chat/completions")!, "default base URL")
    check(store.model == "gpt-4o-mini", "default model")
    check(store.targetLanguage == "Chinese", "default target language")
}

func testSettingsReadWrite() {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    let store = SettingsStore(defaults: defaults)

    store.baseURL = URL(string: "https://example.com/v1/chat/completions")!
    store.model = "test-model"
    store.targetLanguage = "Japanese"

    check(store.baseURL.absoluteString == "https://example.com/v1/chat/completions", "stored base URL")
    check(store.model == "test-model", "stored model")
    check(store.targetLanguage == "Japanese", "stored target language")
}

func makeSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [TestURLProtocol.self]
    return URLSession(configuration: config)
}

func requestBodyData(_ request: URLRequest) -> Data {
    if let data = request.httpBody {
        return data
    }
    guard let stream = request.httpBodyStream else {
        return Data()
    }
    stream.open()
    defer { stream.close() }

    var data = Data()
    let bufferSize = 1024
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }

    while stream.hasBytesAvailable {
        let count = stream.read(buffer, maxLength: bufferSize)
        if count > 0 {
            data.append(buffer, count: count)
        } else {
            break
        }
    }
    return data
}

func runAsync(_ body: @escaping () async throws -> Void) {
    let semaphore = DispatchSemaphore(value: 0)
    var failure: Error?
    Task {
        do {
            try await body()
        } catch {
            failure = error
        }
        semaphore.signal()
    }
    semaphore.wait()
    if let failure {
        fputs("FAIL: \(failure)\n", stderr)
        exit(1)
    }
}

func testTranslationParsesResponse() {
    runAsync {
        let session = makeSession()
        let service = TranslationService(session: session)
        let url = URL(string: "https://example.com/v1/chat/completions")!

        TestURLProtocol.handler = { request in
            check(request.url == url, "translation URL")
            check(request.value(forHTTPHeaderField: "Authorization") == "Bearer key", "authorization header")
            let body = try JSONSerialization.jsonObject(with: requestBodyData(request)) as! [String: Any]
            check(body["model"] as? String == "model", "request model")

            let data = #"{"choices":[{"message":{"content":"你好"}}]}"#.data(using: .utf8)!
            return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
        }

        let output = try await service.translate(
            text: "hello",
            targetLanguage: "Chinese",
            config: .init(baseURL: url, apiKey: "key", model: "model")
        )

        check(output == "你好", "parsed translation")
    }
}

func testTranslationThrowsAPIError() {
    runAsync {
        let session = makeSession()
        let service = TranslationService(session: session)
        let url = URL(string: "https://example.com/v1/chat/completions")!

        TestURLProtocol.handler = { _ in
            let data = #"{"error":{"message":"bad key"}}"#.data(using: .utf8)!
            return (HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil)!, data)
        }

        do {
            _ = try await service.translate(
                text: "hello",
                targetLanguage: "Chinese",
                config: .init(baseURL: url, apiKey: "bad", model: "model")
            )
            check(false, "expected API error")
        } catch let error as TranslationService.Error {
            check(error.localizedDescription == "bad key", "API error message")
        }
    }
}

testSettingsDefaults()
testSettingsReadWrite()
testTranslationParsesResponse()
testTranslationThrowsAPIError()
print("ok")
