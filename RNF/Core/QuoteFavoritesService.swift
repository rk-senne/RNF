import Foundation

struct QuoteFavoritesService {
    private static let key = "rnf_favorite_quotes"

    static func save(_ quote: DisciplineQuote) {
        var favorites = loadAll()
        guard !favorites.contains(where: { $0.text == quote.text }) else { return }
        favorites.append(quote)
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func loadAll() -> [DisciplineQuote] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let quotes = try? JSONDecoder().decode([DisciplineQuote].self, from: data)
        else { return [] }
        return quotes
    }

    static func isFavorite(_ quote: DisciplineQuote) -> Bool {
        loadAll().contains { $0.text == quote.text }
    }

    static func remove(_ quote: DisciplineQuote) {
        var favorites = loadAll()
        favorites.removeAll { $0.text == quote.text }
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func cardTagline() -> String {
        loadAll().first?.text ?? QuoteEngine.todayQuote().text
    }
}
