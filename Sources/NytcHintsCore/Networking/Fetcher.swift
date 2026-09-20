import Foundation

/// Fetches every source concurrently and parses each response.
/// A failure in one source never prevents the others from reporting.
public struct Fetcher: Sendable {
    public var session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchAll(_ sources: [any HintSource], for date: PuzzleDate) async -> [HintSet] {
        await withTaskGroup(of: (Int, HintSet).self) { group in
            for (index, source) in sources.enumerated() {
                group.addTask {
                    (index, HintSet(sourceName: source.name, result: await fetch(source, for: date)))
                }
            }
            var results: [(Int, HintSet)] = []
            for await result in group {
                results.append(result)
            }
            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    public func fetch(_ source: any HintSource, for date: PuzzleDate) async -> Result<[Hint], HintError> {
        var request = URLRequest(url: source.url(for: date))
        request.setValue("nytcHints/0.1", forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            return .failure(.network(error.localizedDescription))
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            return .failure(.badStatus(http.statusCode))
        }

        return Result { () throws(HintError) in try source.parse(data, for: date).validated() }
    }
}
