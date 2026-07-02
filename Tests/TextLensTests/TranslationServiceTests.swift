import XCTest
@testable import TextLensCore

final class TranslationServiceTests: XCTestCase {
    override func tearDown() {
        TestURLProtocol.handler = nil
        super.tearDown()
    }

    func testTranslateParsesResponse() async throws {
        let session = makeSession()
        let service = TranslationService(session: session)
        let url = URL(string: "https://example.com/v1/chat/completions")!

        TestURLProtocol.handler = { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer key")

            let data = #"{"choices":[{"message":{"content":"你好"}}]}"#.data(using: .utf8)!
            return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
        }

        let output = try await service.translate(
            text: "hello",
            targetLanguage: "Chinese",
            config: .init(baseURL: url, apiKey: "key", model: "model")
        )

        XCTAssertEqual(output, "你好")
    }

    func testTranslateThrowsOnAPIError() async {
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
            XCTFail("Expected API error")
        } catch let error as TranslationService.Error {
            XCTAssertEqual(error.localizedDescription, "bad key")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [TestURLProtocol.self]
        return URLSession(configuration: config)
    }
}
