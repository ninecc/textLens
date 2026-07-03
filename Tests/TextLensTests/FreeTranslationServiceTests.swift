import XCTest
@testable import TextLensCore

final class FreeTranslationServiceTests: XCTestCase {
    override func tearDown() {
        TestURLProtocol.handler = nil
        super.tearDown()
    }

    func testTranslateParsesGoogleResponse() async throws {
        let service = FreeTranslationService(session: makeSession())

        TestURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.host, "translate.googleapis.com")
            XCTAssertEqual(Self.queryValue("tl", in: request), "zh-CN")

            let data = #"[[["你好","hello",null,null],["世界"," world",null,null]],null,"en"]"#.data(using: .utf8)!
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
        }

        let output = try await service.translate(text: "hello world", targetLanguage: "Chinese", config: .init(provider: .google))

        XCTAssertEqual(output, "你好世界")
    }

    func testTranslateParsesMyMemoryResponse() async throws {
        let service = FreeTranslationService(session: makeSession())

        TestURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.host, "api.mymemory.translated.net")
            XCTAssertEqual(Self.queryValue("langpair", in: request), "en|zh-CN")

            let data = #"{"responseData":{"translatedText":"你好世界"}}"#.data(using: .utf8)!
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
        }

        let output = try await service.translate(text: "hello world", targetLanguage: "Chinese", config: .init(provider: .myMemory))

        XCTAssertEqual(output, "你好世界")
    }

    func testTranslateParsesYoudaoResponse() async throws {
        let service = FreeTranslationService(
            session: makeSession(),
            nonce: { "salt" },
            timestamp: { 1_700_000_000 }
        )

        TestURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.host, "openapi.youdao.com")
            XCTAssertEqual(Self.queryValue("appKey", in: request), "app")
            XCTAssertEqual(Self.queryValue("salt", in: request), "salt")
            XCTAssertEqual(Self.queryValue("curtime", in: request), "1700000000")
            XCTAssertEqual(Self.queryValue("signType", in: request), "v3")
            XCTAssertEqual(Self.queryValue("from", in: request), "auto")
            XCTAssertEqual(Self.queryValue("to", in: request), "zh-CHS")
            XCTAssertNotNil(Self.queryValue("sign", in: request))

            let data = #"{"errorCode":"0","translation":["你好世界"]}"#.data(using: .utf8)!
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
        }

        let output = try await service.translate(
            text: "hello world",
            targetLanguage: "Chinese",
            config: .init(provider: .youdao, youdaoAppID: "app", youdaoSecret: "secret")
        )

        XCTAssertEqual(output, "你好世界")
    }

    func testTranslateParsesBaiduResponse() async throws {
        let service = FreeTranslationService(session: makeSession(), nonce: { "salt" })

        TestURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.host, "fanyi-api.baidu.com")
            XCTAssertEqual(Self.queryValue("appid", in: request), "app")
            XCTAssertEqual(Self.queryValue("salt", in: request), "salt")
            XCTAssertEqual(Self.queryValue("from", in: request), "auto")
            XCTAssertEqual(Self.queryValue("to", in: request), "zh")
            XCTAssertNotNil(Self.queryValue("sign", in: request))

            let data = #"{"from":"en","to":"zh","trans_result":[{"src":"hello world","dst":"你好世界"}]}"#.data(using: .utf8)!
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
        }

        let output = try await service.translate(
            text: "hello world",
            targetLanguage: "Chinese",
            config: .init(provider: .baidu, baiduAppID: "app", baiduSecret: "secret")
        )

        XCTAssertEqual(output, "你好世界")
    }

    private static func queryValue(_ name: String, in request: URLRequest) -> String? {
        URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == name }?
            .value
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [TestURLProtocol.self]
        return URLSession(configuration: config)
    }
}
