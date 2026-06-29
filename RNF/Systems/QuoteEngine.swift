import Foundation

struct QuoteEngine {

    static func todayQuote() -> DisciplineQuote {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return quote(for: day)
    }

    static func quote(for dayOfYear: Int) -> DisciplineQuote {
        let index = ((dayOfYear - 1) % quotes.count + quotes.count) % quotes.count
        return quotes[index]
    }

    private static let quotes: [DisciplineQuote] = [
        DisciplineQuote(text: "You have power over your mind — not outside events. Realize this, and you will find strength.", author: "Marcus Aurelius"),
        DisciplineQuote(text: "The impediment to action advances action. What stands in the way becomes the way.", author: "Marcus Aurelius"),
        DisciplineQuote(text: "Waste no more time arguing about what a good man should be. Be one.", author: "Marcus Aurelius"),
        DisciplineQuote(text: "At dawn, when you have trouble getting out of bed, tell yourself: I have to go to work — as a human being.", author: "Marcus Aurelius"),
        DisciplineQuote(text: "It is not death that a man should fear, but he should fear never beginning to live.", author: "Marcus Aurelius"),
        DisciplineQuote(text: "The best revenge is not to be like your enemy.", author: "Marcus Aurelius"),
        DisciplineQuote(text: "Never esteem anything as of advantage to you that will make you break your word or lose your self-respect.", author: "Marcus Aurelius"),
        DisciplineQuote(text: "Think of yourself as dead. You have lived your life. Now, take what's left and live it properly.", author: "Marcus Aurelius"),
        DisciplineQuote(text: "We suffer more often in imagination than in reality.", author: "Seneca"),
        DisciplineQuote(text: "It is not that we have a short time to live, but that we waste a great deal of it.", author: "Seneca"),
        DisciplineQuote(text: "Luck is what happens when preparation meets opportunity.", author: "Seneca"),
        DisciplineQuote(text: "Difficulties strengthen the mind, as labor does the body.", author: "Seneca"),
        DisciplineQuote(text: "A gem cannot be polished without friction, nor a man perfected without trials.", author: "Seneca"),
        DisciplineQuote(text: "He who is brave is free.", author: "Seneca"),
        DisciplineQuote(text: "Begin at once to live, and count each separate day as a separate life.", author: "Seneca"),
        DisciplineQuote(text: "No man is free who is not master of himself.", author: "Epictetus"),
        DisciplineQuote(text: "First say to yourself what you would be; and then do what you have to do.", author: "Epictetus"),
        DisciplineQuote(text: "It's not what happens to you, but how you react to it that matters.", author: "Epictetus"),
        DisciplineQuote(text: "Make the best use of what is in your power, and take the rest as it happens.", author: "Epictetus"),
        DisciplineQuote(text: "He who laughs at himself never runs out of things to laugh at.", author: "Epictetus"),
        DisciplineQuote(text: "Don't explain your philosophy. Embody it.", author: "Epictetus"),
        DisciplineQuote(text: "Suffering is nothing. It's all in the mind. The body can take damn near anything.", author: "David Goggins"),
        DisciplineQuote(text: "You are in danger of living a life so comfortable and soft that you will die without ever realizing your potential.", author: "David Goggins"),
        DisciplineQuote(text: "The most important conversations you'll ever have are the ones you'll have with yourself.", author: "David Goggins"),
        DisciplineQuote(text: "Don't stop when you're tired. Stop when you're done.", author: "David Goggins"),
        DisciplineQuote(text: "We live in a world where mediocrity is often rewarded. Do not be that person.", author: "David Goggins"),
        DisciplineQuote(text: "You want to be uncommon amongst uncommon people. Period.", author: "David Goggins"),
        DisciplineQuote(text: "Motivation is crap. Motivation comes and goes. When you're driven, whatever is in front of you will get destroyed.", author: "David Goggins"),
        DisciplineQuote(text: "Discipline equals freedom.", author: "Jocko Willink"),
        DisciplineQuote(text: "Don't expect to be motivated every day to get out there and make things happen. You won't be. Don't count on motivation. Count on discipline.", author: "Jocko Willink"),
        DisciplineQuote(text: "The more you practice, the better you get, the more freedom you have to create.", author: "Jocko Willink"),
        DisciplineQuote(text: "Stand up. Get after it. Nobody is coming to save you.", author: "Jocko Willink"),
        DisciplineQuote(text: "Default aggressive. When in doubt, act.", author: "Jocko Willink"),
        DisciplineQuote(text: "Get comfortable being uncomfortable.", author: "Jocko Willink"),
        DisciplineQuote(text: "You are not your habits. You can replace old habits with new ones.", author: "James Clear"),
        DisciplineQuote(text: "Every action you take is a vote for the type of person you wish to become.", author: "James Clear"),
        DisciplineQuote(text: "You do not rise to the level of your goals. You fall to the level of your systems.", author: "James Clear"),
        DisciplineQuote(text: "The task of breaking a bad habit is like uprooting a powerful oak within us.", author: "James Clear"),
        DisciplineQuote(text: "Habits are the compound interest of self-improvement.", author: "James Clear"),
        DisciplineQuote(text: "Success is the product of daily habits — not once-in-a-lifetime transformations.", author: "James Clear"),
        DisciplineQuote(text: "The obstacle is the way.", author: "Ryan Holiday"),
        DisciplineQuote(text: "Ego is the enemy of what you want and of what you have.", author: "Ryan Holiday"),
        DisciplineQuote(text: "Stillness is the key. The world will tell you otherwise. Ignore it.", author: "Ryan Holiday"),
        DisciplineQuote(text: "You never know which blow will break the stone. Keep hitting.", author: "Ryan Holiday"),
        DisciplineQuote(text: "Self-discipline is when your conscience tells you to do something and you don't talk back.", author: "Ryan Holiday"),
        DisciplineQuote(text: "Desire is a contract you make with yourself to be unhappy until you get what you want.", author: "Naval Ravikant"),
        DisciplineQuote(text: "A fit body, a calm mind, a house full of love. These things cannot be bought — they must be earned.", author: "Naval Ravikant"),
        DisciplineQuote(text: "The hardest thing is not doing what you want — it's knowing what you want.", author: "Naval Ravikant"),
        DisciplineQuote(text: "If you can't see yourself working with someone for life, don't work with them for a day.", author: "Naval Ravikant"),
        DisciplineQuote(text: "Play long-term games with long-term people.", author: "Naval Ravikant"),
    ]
}
