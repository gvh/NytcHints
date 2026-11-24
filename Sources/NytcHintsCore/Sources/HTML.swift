import Foundation

/// Minimal HTML helpers for source parsers.
enum HTML {
    static func string(from data: Data) throws(HintError) -> String {
        guard let html = String(data: data, encoding: .utf8) else {
            throw .parse("response is not UTF-8")
        }
        return html
    }

    /// The HTML after the first `<h2>` whose text contains `keyword`, up to the next `<h2`.
    /// Sites put answers in later sections, so confining parsing to this slice keeps them out.
    static func section(afterHeadingContaining keyword: String, in html: String) -> Substring? {
        // Headings may wrap their text in inner tags (`<h2><span>…</span></h2>`), so strip them before matching.
        let heading = /<h2[^>]*>(?<title>.*?)<\/h2>/.dotMatchesNewlines()
        // Not `localizedCaseInsensitiveContains`: it depends on the user's locale (Turkish "I"/"ı").
        guard let start = html.matches(of: heading).first(where: { text(from: String($0.title)).range(of: keyword, options: .caseInsensitive) != nil }) else {
            return nil
        }
        let rest = html[start.range.upperBound...]
        let end = rest.range(of: "<h2", options: .caseInsensitive)?.lowerBound ?? rest.endIndex
        return rest[..<end]
    }

    /// The `content` of `<meta property="…">`, if present.
    /// Handles single or double quotes, either attribute order, and `>` inside attribute values.
    static func metaContent(property: String, in html: String) -> String? {
        for tag in html.matches(of: /<meta\s(?:"[^"]*"|'[^']*'|[^>"'])*>/) {
            let attributes = attributes(of: tag.output)
            if attributes["property"] == property, let content = attributes["content"] {
                return decodeEntities(content)
            }
        }
        return nil
    }

    /// The quoted attributes of one tag, keyed by lowercased name (the first occurrence wins).
    private static func attributes(of tag: Substring) -> [String: String] {
        var result: [String: String] = [:]
        for match in tag.matches(of: /(?<name>[\w:-]+)\s*=\s*(?:"(?<double>[^"]*)"|'(?<single>[^']*)')/) {
            let name = match.name.lowercased()
            if result[name] == nil {
                result[name] = String(match.double ?? match.single ?? "")
            }
        }
        return result
    }

    /// Checks that the article was published close to the puzzle date.
    /// Articles go up the evening before the puzzle date. The timestamp's date is read as written
    /// (often UTC), so it can be a day ahead of the local puzzle day, and a day or two of slack
    /// covers early postings. The window is the published day being 3 days before to 1 day after
    /// `date`. It guards against a site redirecting a date's URL to a different year's puzzle.
    static func checkPublished(_ html: String, for date: PuzzleDate) throws(HintError) {
        guard let published = metaContent(property: "article:published_time", in: html),
              let day = PuzzleDate(string: String(published.prefix(10)))
        else { throw .parse("publish date not found") }
        guard (-1...3).contains(date.days(since: day)) else {
            throw .parse("article was published \(day), not for \(date)")
        }
    }

    /// Strips tags, decodes entities, and collapses whitespace.
    static func text(from html: String) -> String {
        let stripped = html.replacing(/<[^>]+>/, with: " ")
        let decoded = decodeEntities(stripped)
        let collapsed = decoded.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        // Tags were replaced by spaces; drop the ones this leaves before punctuation ("Valjean .").
        return collapsed.replacing(/\s(?<p>[.,;:!?)])/) { String($0.p) }
    }

    private static let named: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": " ",
        "rsquo": "\u{2019}", "lsquo": "\u{2018}", "rdquo": "\u{201D}", "ldquo": "\u{201C}",
        "mdash": "\u{2014}", "ndash": "\u{2013}", "hellip": "\u{2026}",
    ]

    static func decodeEntities(_ string: String) -> String {
        string.replacing(/&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);/) { match in
            let entity = String(match.1)
            if entity.hasPrefix("#x"), let code = UInt32(entity.dropFirst(2), radix: 16), let scalar = Unicode.Scalar(code) {
                return String(Character(scalar))
            }
            if entity.hasPrefix("#"), let code = UInt32(entity.dropFirst()), let scalar = Unicode.Scalar(code) {
                return String(Character(scalar))
            }
            return named[entity] ?? String(match.0)
        }
    }
}
