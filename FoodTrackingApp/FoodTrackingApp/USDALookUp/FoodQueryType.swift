//
//  FoodQueryType.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 2/2/26.
//


enum FoodQueryType {
    case single
    case mixed
}

struct FoodQueryClassifier {
    private static let dishKeywords: Set<String> = [
        "pizza","burger","hamburger","cheeseburger","pho","ramen","burrito","taco","sandwich",
        "salad","pasta","lasagna","curry","stir","stirfry","stir-fry","fried","rice","sushi",
        "soup","stew","chili","casserole","dumplings","noodles","wrap","quesadilla","nachos",
        "shawarma","kebab","bowl"
    ]

    private static let singleKeywords: Set<String> = [
        "salmon","tuna","chicken","breast","thigh","steak","fillet","egg","milk","yogurt",
        "oats","rice","potato","banana","apple","broccoli","spinach","beans","lentils","tofu"
    ]

    private static let connectors: Set<String> = ["with","and","+","&","in","on"]
    private static let mealWords: Set<String> = ["combo","meal","plate","platter","bowl"]

    static func classify(_ raw: String) -> FoodQueryType {
        let s = normalize(raw)
        print("Food normalized:", s)
        let tokens = tokenize(s)

        var dishScore = 0
        var singleScore = 0

        // dish keywords
        if tokens.contains(where: { dishKeywords.contains($0) }) { dishScore += 3 }

        // single keywords
        if tokens.contains(where: { singleKeywords.contains($0) }) { singleScore += 2 }

        // connectors indicate mixtures
        if tokens.contains(where: { connectors.contains($0) }) { dishScore += 2 }

        // meal words indicate prepared dishes
        if tokens.contains(where: { mealWords.contains($0) }) { dishScore += 2 }

        // commas or multiple items
        if s.contains(",") { dishScore += 2 }

        // word count heuristic
        if tokens.count >= 4 { dishScore += 1 }
        if tokens.count <= 2 { singleScore += 1 }

        return (dishScore > singleScore) ? .mixed : .single
    }

    private static func normalize(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s,+&-]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func tokenize(_ s: String) -> [String] {
        s.split(separator: " ").map { String($0) }
    }
}
