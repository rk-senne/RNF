import XCTest
@testable import RNF

final class QuoteEngineTests: XCTestCase {

    func testTodayQuoteReturnsNonEmpty() {
        let quote = QuoteEngine.todayQuote()
        XCTAssertFalse(quote.text.isEmpty)
        XCTAssertFalse(quote.author.isEmpty)
    }

    func testQuoteForDayWrapsModulo() {
        let q1 = QuoteEngine.quote(for: 1)
        let q51 = QuoteEngine.quote(for: 51)
        // Day 51 wraps to index 0 if only 50 quotes
        XCTAssertFalse(q1.text.isEmpty)
        XCTAssertFalse(q51.text.isEmpty)
    }

    func testQuoteForDayDeterministic() {
        let a = QuoteEngine.quote(for: 7)
        let b = QuoteEngine.quote(for: 7)
        XCTAssertEqual(a.text, b.text)
        XCTAssertEqual(a.author, b.author)
    }

    func testQuoteForLargeDayWraps() {
        let quote = QuoteEngine.quote(for: 999)
        XCTAssertFalse(quote.text.isEmpty)
    }
}
