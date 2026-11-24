import Foundation
import Testing
@testable import NytcHintsCore

/// Serves canned responses by URL so `Fetcher` can be tested without the network.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    enum Reply: Sendable {
        case status(Int, Data)
        case failure(URLError.Code)
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var replies: [URL: Reply] = [:]

    static func set(_ reply: Reply, for url: URL) {
        lock.withLock { replies[url] = reply }
    }

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        guard let url = request.url, let reply = Self.lock.withLock({ Self.replies[url] }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        switch reply {
        case .status(let code, let data):
            let response = HTTPURLResponse(url: url, statusCode: code, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let code):
            client?.urlProtocol(self, didFailWithError: URLError(code))
        }
    }
}

/// Returns the response body as a comma-separated list of hint texts, one per color in order.
private struct StubSource: HintSource {
    let name = "Stub"
    let url: URL

    func url(for date: PuzzleDate) -> URL { url }

    func parse(_ data: Data, for date: PuzzleDate) throws(HintError) -> [Hint] {
        let texts = String(decoding: data, as: UTF8.self).split(separator: "|").map(String.init)
        return zip(HintColor.allCases, texts).map { Hint(color: $0, text: $1) }
    }
}

struct FetcherTests {
    let date = PuzzleDate(year: 2026, month: 9, day: 18)!

    private func source(_ name: String) -> StubSource {
        StubSource(url: URL(string: "https://stub.test/\(name)")!)
    }

    private func fetch(_ source: StubSource, _ reply: StubURLProtocol.Reply) async -> Result<[Hint], HintError> {
        StubURLProtocol.set(reply, for: source.url)
        return await Fetcher(session: StubURLProtocol.session()).fetch(source, for: date)
    }

    @Test func successReturnsValidatedHints() async throws {
        let result = await fetch(source("ok"), .status(200, Data("a|b|c|d".utf8)))
        #expect(try result.get().map(\.text) == ["a", "b", "c", "d"])
    }

    @Test func badStatusIsReported() async {
        let result = await fetch(source("missing"), .status(404, Data()))
        guard case .failure(.badStatus(404)) = result else {
            Issue.record("expected badStatus(404), got \(result)")
            return
        }
    }

    @Test func networkErrorIsReported() async {
        let result = await fetch(source("offline"), .failure(.notConnectedToInternet))
        guard case .failure(.network) = result else {
            Issue.record("expected a network error, got \(result)")
            return
        }
    }

    @Test func parseFailureIsReported() async {
        let result = await fetch(source("short"), .status(200, Data("a|b".utf8)))
        guard case .failure(.parse) = result else {
            Issue.record("expected a parse error, got \(result)")
            return
        }
    }

    @Test func answerListIsWithheldWithoutShowingIt() async throws {
        let result = await fetch(source("leak"), .status(200, Data("a|b|c|BEND, FLEX, TWIST, TURN".utf8)))
        let hints = try result.get()
        #expect(hints.map(\.isWithheld) == [false, false, false, true])
        #expect(!hints.contains { $0.text.contains("BEND") })
    }

    @Test func fetchAllKeepsSourceOrderAndIsolatesFailures() async {
        let good = source("all-good"), bad = source("all-bad")
        StubURLProtocol.set(.status(200, Data("a|b|c|d".utf8)), for: good.url)
        StubURLProtocol.set(.status(500, Data()), for: bad.url)
        let sets = await Fetcher(session: StubURLProtocol.session()).fetchAll([bad, good], for: date)
        #expect(sets.map(\.isFailure) == [true, false])
    }
}
