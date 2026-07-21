import SwiftUI
import SwiftData
import MetabolicCore

/// Seeds 7 days of plausible demo history the first time the app launches in demo mode,
/// so the dashboard "looks alive" instead of empty. No-op once real data exists.
enum DemoDataSeeder {
    static func seedIfNeeded(context: ModelContext, appState: AppState) {
        guard appState.demoMode else { return }
        let existingCount = (try? context.fetchCount(FetchDescriptor<FoodEntry>())) ?? 0
        guard existingCount == 0 else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        let breakfasts: [(String, Double, Double, Double, Double)] = [
            ("Oatmeal with Banana", 350, 12, 62, 7),
            ("Greek Yogurt & Berries", 280, 20, 34, 6),
            ("Scrambled Eggs & Toast", 320, 22, 28, 14),
            ("Avocado Toast", 340, 10, 38, 17),
            ("Protein Smoothie", 310, 28, 36, 6),
            ("Overnight Oats", 360, 14, 58, 9),
            ("Veggie Omelet", 300, 24, 12, 18),
        ]
        let lunches: [(String, Double, Double, Double, Double)] = [
            ("Grilled Chicken & Rice", 600, 48, 62, 16),
            ("Turkey Wrap & Salad", 560, 38, 54, 20),
            ("Quinoa Buddha Bowl", 540, 22, 68, 18),
            ("Chicken Caesar Salad", 520, 40, 24, 28),
            ("Beef & Veggie Stir-fry", 610, 42, 58, 22),
            ("Tuna Salad Sandwich", 480, 34, 46, 16),
            ("Falafel Pita Bowl", 580, 20, 74, 20),
        ]
        let dinners: [(String, Double, Double, Double, Double)] = [
            ("Grilled Salmon & Veggies", 550, 42, 24, 30),
            ("Steak & Sweet Potato", 620, 46, 42, 26),
            ("Baked Cod & Quinoa", 480, 38, 44, 14),
            ("Chicken Fajita Bowl", 560, 40, 50, 20),
            ("Shrimp Stir-fry", 500, 36, 46, 16),
            ("Turkey Meatballs & Pasta", 590, 38, 62, 18),
            ("Tofu & Vegetable Curry", 470, 24, 52, 18),
        ]
        let snacks: [(String, Double, Double, Double, Double)] = [
            ("Greek Yogurt", 150, 15, 12, 4),
            ("Almonds (1 oz)", 165, 6, 6, 14),
            ("Apple & Peanut Butter", 190, 6, 22, 9),
            ("Protein Bar", 200, 18, 20, 7),
            ("Cottage Cheese & Pineapple", 170, 18, 16, 3),
            ("Hummus & Carrots", 160, 6, 18, 8),
            ("Mixed Berries", 90, 1, 22, 1),
        ]

        let workoutTitles = ["Full Body Strength", "Upper Body Push", "Lower Body Power", "Core & Conditioning"]
        let workoutFocuses: [DayFocus] = [.fullBody, .upperBody, .lowerBody, .core]

        // Walk from 6 days ago up to today so "today" is the last (most recent) day seeded.
        for offset in stride(from: 6, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let isToday = offset == 0
            let variant = 6 - offset // 0...6, stable per-day variety

            func time(_ hour: Int, _ minute: Int) -> Date {
                calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
            }

            let breakfast = breakfasts[variant % breakfasts.count]
            context.insert(FoodEntry(
                date: time(8, 0), mealType: .breakfast, name: breakfast.0,
                calories: breakfast.1, proteinG: breakfast.2, carbsG: breakfast.3, fatG: breakfast.4,
                source: .search
            ))

            let lunch = lunches[variant % lunches.count]
            context.insert(FoodEntry(
                date: time(12, 45), mealType: .lunch, name: lunch.0,
                calories: lunch.1, proteinG: lunch.2, carbsG: lunch.3, fatG: lunch.4,
                source: .search
            ))

            if !isToday {
                let dinner = dinners[variant % dinners.count]
                context.insert(FoodEntry(
                    date: time(19, 0), mealType: .dinner, name: dinner.0,
                    calories: dinner.1, proteinG: dinner.2, carbsG: dinner.3, fatG: dinner.4,
                    source: .search
                ))

                if variant % 3 != 2 {
                    let snack = snacks[variant % snacks.count]
                    context.insert(FoodEntry(
                        date: time(16, 0), mealType: .snack, name: snack.0,
                        calories: snack.1, proteinG: snack.2, carbsG: snack.3, fatG: snack.4,
                        source: .manual
                    ))
                }
            }

            // Water: 5-8 entries/day; today only gets a few (so the ring reads as "in progress").
            let waterCount = isToday ? 3 : 5 + (variant % 4)
            for w in 0..<waterCount {
                let hour = 7 + (w * 90) / 60
                context.insert(WaterEntry(date: time(min(hour, 21), 15), amountML: 250))
            }

            // Workouts on alternating days.
            if !isToday && offset % 2 == 1 {
                let idx = variant % workoutTitles.count
                let minutes = 25 + (variant * 3) % 16
                let calories = 180 + (variant * 17) % 141
                context.insert(WorkoutLog(
                    date: time(18, 0), title: workoutTitles[idx], focus: workoutFocuses[idx],
                    minutes: minutes, calories: calories, completedExerciseIDs: []
                ))
            }

            // Weight drifts 75.0 -> 74.4 kg across the week.
            let progress = Double(variant) / 6.0
            let weight = ((75.0 - 0.6 * progress) * 10).rounded() / 10
            context.insert(WeightEntry(date: time(7, 0), weightKg: weight))
        }

        context.insert(ScanRecord(
            date: calendar.date(byAdding: .day, value: -2, to: today) ?? today,
            barcode: "3017620422003", name: "Dark Chocolate 85%", brand: "Lindt",
            scoreValue: 71, rating: .good, imageURLString: nil
        ))
        context.insert(ScanRecord(
            date: calendar.date(byAdding: .day, value: -4, to: today) ?? today,
            barcode: "5449000000996", name: "Cola Zero", brand: "Coca-Cola",
            scoreValue: 34, rating: .poor, imageURLString: nil
        ))

        try? context.save()
    }
}
