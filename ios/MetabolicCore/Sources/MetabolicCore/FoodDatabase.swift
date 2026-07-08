import Foundation

public enum FoodDatabase {

    /// Case- and diacritic-insensitive substring search over name + brand,
    /// tighter (shorter) names first, capped at 25 results.
    public static func search(_ query: String) -> [FoodItem] {
        let needle = query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }
        return common
            .filter {
                let haystack = ($0.name + " " + ($0.brand ?? ""))
                    .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
                return haystack.contains(needle)
            }
            .sorted { $0.name.count < $1.name.count }
            .prefix(25)
            .map { $0 }
    }

    public static let common: [FoodItem] = [
        // Proteins
        FoodItem(id: "chicken-breast", name: "Chicken breast, grilled", servingDescription: "100 g", calories: 165, proteinG: 31, carbsG: 0, fatG: 3.6),
        FoodItem(id: "chicken-thigh", name: "Chicken thigh, roasted", servingDescription: "100 g", calories: 209, proteinG: 26, carbsG: 0, fatG: 10.9),
        FoodItem(id: "salmon", name: "Salmon fillet, baked", servingDescription: "100 g", calories: 208, proteinG: 20, carbsG: 0, fatG: 13),
        FoodItem(id: "tuna-canned", name: "Tuna, canned in water", servingDescription: "1 can (140 g)", calories: 128, proteinG: 28, carbsG: 0, fatG: 1.2),
        FoodItem(id: "ground-beef", name: "Ground beef 85/15, cooked", servingDescription: "100 g", calories: 250, proteinG: 26, carbsG: 0, fatG: 15),
        FoodItem(id: "steak-sirloin", name: "Sirloin steak, grilled", servingDescription: "100 g", calories: 206, proteinG: 29, carbsG: 0, fatG: 9.6),
        FoodItem(id: "pork-chop", name: "Pork chop, grilled", servingDescription: "100 g", calories: 231, proteinG: 26, carbsG: 0, fatG: 13),
        FoodItem(id: "turkey-breast", name: "Turkey breast, roasted", servingDescription: "100 g", calories: 135, proteinG: 30, carbsG: 0, fatG: 1),
        FoodItem(id: "egg", name: "Egg, large", servingDescription: "1 egg (50 g)", calories: 72, proteinG: 6.3, carbsG: 0.4, fatG: 4.8),
        FoodItem(id: "egg-white", name: "Egg white", servingDescription: "1 white (33 g)", calories: 17, proteinG: 3.6, carbsG: 0.2, fatG: 0.1),
        FoodItem(id: "shrimp", name: "Shrimp, cooked", servingDescription: "100 g", calories: 99, proteinG: 24, carbsG: 0.2, fatG: 0.3),
        FoodItem(id: "tofu-firm", name: "Tofu, firm", servingDescription: "100 g", calories: 76, proteinG: 8, carbsG: 1.9, fatG: 4.8),
        FoodItem(id: "tempeh", name: "Tempeh", servingDescription: "100 g", calories: 192, proteinG: 20, carbsG: 7.6, fatG: 11),
        FoodItem(id: "whey-scoop", name: "Whey protein powder", servingDescription: "1 scoop (30 g)", calories: 120, proteinG: 24, carbsG: 3, fatG: 1.5),

        // Grains & starches
        FoodItem(id: "brown-rice", name: "Brown rice, cooked", servingDescription: "1 cup (195 g)", calories: 216, proteinG: 5, carbsG: 45, fatG: 1.8),
        FoodItem(id: "white-rice", name: "White rice, cooked", servingDescription: "1 cup (158 g)", calories: 205, proteinG: 4.3, carbsG: 45, fatG: 0.4),
        FoodItem(id: "quinoa", name: "Quinoa, cooked", servingDescription: "1 cup (185 g)", calories: 222, proteinG: 8, carbsG: 39, fatG: 3.6),
        FoodItem(id: "oatmeal", name: "Oatmeal, cooked with water", servingDescription: "1 cup (234 g)", calories: 166, proteinG: 6, carbsG: 28, fatG: 3.6),
        FoodItem(id: "pasta", name: "Pasta, cooked", servingDescription: "1 cup (140 g)", calories: 220, proteinG: 8, carbsG: 43, fatG: 1.3),
        FoodItem(id: "bread-whole-wheat", name: "Whole wheat bread", servingDescription: "1 slice (28 g)", calories: 69, proteinG: 3.6, carbsG: 12, fatG: 0.9),
        FoodItem(id: "bread-white", name: "White bread", servingDescription: "1 slice (25 g)", calories: 67, proteinG: 2.3, carbsG: 13, fatG: 0.8),
        FoodItem(id: "bagel", name: "Bagel, plain", servingDescription: "1 bagel (98 g)", calories: 245, proteinG: 10, carbsG: 48, fatG: 1.5),
        FoodItem(id: "tortilla-flour", name: "Flour tortilla", servingDescription: "1 medium (45 g)", calories: 138, proteinG: 3.7, carbsG: 22, fatG: 3.6),
        FoodItem(id: "sweet-potato", name: "Sweet potato, baked", servingDescription: "1 medium (114 g)", calories: 103, proteinG: 2.3, carbsG: 24, fatG: 0.2),
        FoodItem(id: "potato-baked", name: "Potato, baked with skin", servingDescription: "1 medium (173 g)", calories: 161, proteinG: 4.3, carbsG: 37, fatG: 0.2),

        // Fruits
        FoodItem(id: "banana", name: "Banana, medium", servingDescription: "1 banana (118 g)", calories: 105, proteinG: 1.3, carbsG: 27, fatG: 0.4),
        FoodItem(id: "apple", name: "Apple, medium", servingDescription: "1 apple (182 g)", calories: 95, proteinG: 0.5, carbsG: 25, fatG: 0.3),
        FoodItem(id: "orange", name: "Orange, medium", servingDescription: "1 orange (131 g)", calories: 62, proteinG: 1.2, carbsG: 15, fatG: 0.2),
        FoodItem(id: "blueberries", name: "Blueberries", servingDescription: "1 cup (148 g)", calories: 84, proteinG: 1.1, carbsG: 21, fatG: 0.5),
        FoodItem(id: "strawberries", name: "Strawberries", servingDescription: "1 cup (152 g)", calories: 49, proteinG: 1, carbsG: 12, fatG: 0.5),
        FoodItem(id: "grapes", name: "Grapes", servingDescription: "1 cup (151 g)", calories: 104, proteinG: 1.1, carbsG: 27, fatG: 0.2),
        FoodItem(id: "avocado", name: "Avocado", servingDescription: "1/2 fruit (100 g)", calories: 160, proteinG: 2, carbsG: 8.5, fatG: 14.7),
        FoodItem(id: "mango", name: "Mango, sliced", servingDescription: "1 cup (165 g)", calories: 99, proteinG: 1.4, carbsG: 25, fatG: 0.6),
        FoodItem(id: "watermelon", name: "Watermelon, diced", servingDescription: "1 cup (152 g)", calories: 46, proteinG: 0.9, carbsG: 11.5, fatG: 0.2),

        // Vegetables
        FoodItem(id: "broccoli", name: "Broccoli, steamed", servingDescription: "1 cup (156 g)", calories: 55, proteinG: 3.7, carbsG: 11, fatG: 0.6),
        FoodItem(id: "spinach", name: "Spinach, raw", servingDescription: "2 cups (60 g)", calories: 14, proteinG: 1.7, carbsG: 2.2, fatG: 0.2),
        FoodItem(id: "carrots", name: "Carrots, raw", servingDescription: "1 cup (128 g)", calories: 52, proteinG: 1.2, carbsG: 12, fatG: 0.3),
        FoodItem(id: "bell-pepper", name: "Bell pepper, raw", servingDescription: "1 medium (119 g)", calories: 31, proteinG: 1, carbsG: 7.2, fatG: 0.4),
        FoodItem(id: "cucumber", name: "Cucumber, sliced", servingDescription: "1 cup (104 g)", calories: 16, proteinG: 0.7, carbsG: 3.8, fatG: 0.1),
        FoodItem(id: "tomato", name: "Tomato, medium", servingDescription: "1 tomato (123 g)", calories: 22, proteinG: 1.1, carbsG: 4.8, fatG: 0.2),
        FoodItem(id: "mixed-salad", name: "Mixed green salad, plain", servingDescription: "2 cups (85 g)", calories: 15, proteinG: 1.2, carbsG: 2.9, fatG: 0.2),
        FoodItem(id: "green-beans", name: "Green beans, steamed", servingDescription: "1 cup (125 g)", calories: 44, proteinG: 2.4, carbsG: 10, fatG: 0.4),

        // Legumes & nuts
        FoodItem(id: "black-beans", name: "Black beans, cooked", servingDescription: "1 cup (172 g)", calories: 227, proteinG: 15, carbsG: 41, fatG: 0.9),
        FoodItem(id: "chickpeas", name: "Chickpeas, cooked", servingDescription: "1 cup (164 g)", calories: 269, proteinG: 14.5, carbsG: 45, fatG: 4.2),
        FoodItem(id: "lentils", name: "Lentils, cooked", servingDescription: "1 cup (198 g)", calories: 230, proteinG: 18, carbsG: 40, fatG: 0.8),
        FoodItem(id: "almonds", name: "Almonds", servingDescription: "1 oz (28 g)", calories: 164, proteinG: 6, carbsG: 6.1, fatG: 14.2),
        FoodItem(id: "peanut-butter", name: "Peanut butter", servingDescription: "2 tbsp (32 g)", calories: 188, proteinG: 8, carbsG: 6.9, fatG: 16),
        FoodItem(id: "walnuts", name: "Walnuts", servingDescription: "1 oz (28 g)", calories: 185, proteinG: 4.3, carbsG: 3.9, fatG: 18.5),
        FoodItem(id: "hummus", name: "Hummus", servingDescription: "2 tbsp (30 g)", calories: 70, proteinG: 2, carbsG: 6, fatG: 5),

        // Dairy
        FoodItem(id: "greek-yogurt", name: "Greek yogurt, plain nonfat", servingDescription: "1 cup (245 g)", calories: 146, proteinG: 25, carbsG: 9, fatG: 0.7),
        FoodItem(id: "cottage-cheese", name: "Cottage cheese, 2%", servingDescription: "1 cup (226 g)", calories: 183, proteinG: 24, carbsG: 11, fatG: 5),
        FoodItem(id: "cheddar", name: "Cheddar cheese", servingDescription: "1 oz (28 g)", calories: 114, proteinG: 6.5, carbsG: 0.9, fatG: 9.3),
        FoodItem(id: "milk-2pct", name: "Milk, 2%", servingDescription: "1 cup (244 ml)", calories: 122, proteinG: 8, carbsG: 12, fatG: 4.8),
        FoodItem(id: "milk-almond", name: "Almond milk, unsweetened", servingDescription: "1 cup (240 ml)", calories: 30, proteinG: 1, carbsG: 1, fatG: 2.5),
        FoodItem(id: "mozzarella", name: "Mozzarella, part-skim", servingDescription: "1 oz (28 g)", calories: 72, proteinG: 6.9, carbsG: 0.8, fatG: 4.5),

        // Fats & condiments
        FoodItem(id: "olive-oil", name: "Olive oil", servingDescription: "1 tbsp (14 g)", calories: 119, proteinG: 0, carbsG: 0, fatG: 13.5),
        FoodItem(id: "butter", name: "Butter", servingDescription: "1 tbsp (14 g)", calories: 102, proteinG: 0.1, carbsG: 0, fatG: 11.5),
        FoodItem(id: "mayo", name: "Mayonnaise", servingDescription: "1 tbsp (13 g)", calories: 94, proteinG: 0.1, carbsG: 0.1, fatG: 10.3),
        FoodItem(id: "ketchup", name: "Ketchup", servingDescription: "1 tbsp (17 g)", calories: 17, proteinG: 0.2, carbsG: 4.5, fatG: 0),

        // Snacks, drinks & fast food
        FoodItem(id: "dark-chocolate", name: "Dark chocolate, 70-85%", servingDescription: "1 oz (28 g)", calories: 170, proteinG: 2.2, carbsG: 13, fatG: 12.1),
        FoodItem(id: "potato-chips", name: "Potato chips", servingDescription: "1 oz (28 g)", calories: 152, proteinG: 2, carbsG: 15, fatG: 10),
        FoodItem(id: "protein-bar", name: "Protein bar", servingDescription: "1 bar (60 g)", calories: 210, proteinG: 20, carbsG: 22, fatG: 7),
        FoodItem(id: "granola", name: "Granola", servingDescription: "1/2 cup (56 g)", calories: 260, proteinG: 6, carbsG: 37, fatG: 10),
        FoodItem(id: "orange-juice", name: "Orange juice", servingDescription: "1 cup (248 ml)", calories: 112, proteinG: 1.7, carbsG: 26, fatG: 0.5),
        FoodItem(id: "cola", name: "Cola", servingDescription: "1 can (355 ml)", calories: 140, proteinG: 0, carbsG: 39, fatG: 0),
        FoodItem(id: "latte", name: "Latte with 2% milk", servingDescription: "12 oz (355 ml)", calories: 150, proteinG: 10, carbsG: 15, fatG: 6),
        FoodItem(id: "cheese-pizza", name: "Cheese pizza", servingDescription: "1 slice (107 g)", calories: 285, proteinG: 12, carbsG: 36, fatG: 10),
        FoodItem(id: "hamburger", name: "Hamburger, single patty", servingDescription: "1 burger (226 g)", calories: 540, proteinG: 25, carbsG: 40, fatG: 31),
        FoodItem(id: "french-fries", name: "French fries", servingDescription: "medium (117 g)", calories: 365, proteinG: 4, carbsG: 48, fatG: 17),
        FoodItem(id: "burrito-chicken", name: "Chicken burrito", servingDescription: "1 burrito (300 g)", calories: 570, proteinG: 33, carbsG: 66, fatG: 18),
        FoodItem(id: "sushi-roll", name: "California roll", servingDescription: "8 pieces (220 g)", calories: 297, proteinG: 9, carbsG: 55, fatG: 4.9),
    ]
}
