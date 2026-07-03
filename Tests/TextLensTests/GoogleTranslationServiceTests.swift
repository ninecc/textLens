import XCTest
@testable import TextLensCore

final class GoogleTranslationServiceTests: XCTestCase {
    override func tearDown() {
        TestURLProtocol.handler = nil
        super.tearDown()
    }

    func testTranslateParsesGoogleResponse() async throws {
        let session = makeSession()
        let service = GoogleTranslationService(session: session)

        TestURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.scheme, "https")
            XCTAssertEqual(request.url?.host, "translate.googleapis.com")
            XCTAssertEqual(request.url?.path, "/translate_a/single")

            let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
            XCTAssertEqual(query.first { $0.name == "client" }?.value, "gtx")
            XCTAssertEqual(query.first { $0.name == "sl" }?.value, "auto")
            XCTAssertEqual(query.first { $0.name == "tl" }?.value, "zh-CN")
            XCTAssertEqual(query.first { $0.name == "dt" }?.value, "t")
            XCTAssertEqual(query.first { $0.name == "q" }?.value, "hello world")

            let data = #"[[["你好","hello",null,null],["世界"," world",null,null]],null,"en"]"#.data(using: .utf8)!
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
        }

        let output = try await service.translate(text: "hello world", targetLanguage: "Chinese")

        XCTAssertEqual(output, "你好世界")
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [TestURLProtocol.self]
        return URLSession(configuration: config)
    }
}
