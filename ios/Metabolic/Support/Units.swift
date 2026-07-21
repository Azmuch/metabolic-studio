import Foundation

/// Weight/height display + conversion helpers shared by onboarding, profile editing, and
/// the You tab. Storage always stays metric (kg/cm) — this only formats for display and
/// converts user-entered imperial values back to metric.
enum Units {
    private static let poundsPerKg = 2.20462
    private static let cmPerInch = 2.54
    private static let mlPerFluidOunce = 29.5735

    // MARK: - Water (stored in ml; displayed per the user's unit system)

    /// A logged/quick-add amount: "250 ml" (metric) or "8 oz" (US).
    static func waterAmountString(ml: Int, system: UnitSystem) -> String {
        switch system {
        case .metric:
            return "\(ml) ml"
        case .imperial:
            return "\(Int((Double(ml) / mlPerFluidOunce).rounded())) oz"
        }
    }

    /// A goal/total: "2.0 L" (metric) or "68 oz" (US).
    static func waterGoalString(ml: Int, system: UnitSystem) -> String {
        switch system {
        case .metric:
            return String(format: "%.1f L", Double(ml) / 1000)
        case .imperial:
            return "\(Int((Double(ml) / mlPerFluidOunce).rounded())) oz"
        }
    }

    /// Quick-add presets in familiar real-world sizes for the active unit system. Amounts are
    /// stored in ml; labels read in the user's units.
    static func waterQuickAdds(system: UnitSystem) -> [(label: String, ml: Int)] {
        switch system {
        case .metric:
            return [("150 ml", 150), ("250 ml", 250), ("500 ml", 500), ("750 ml", 750)]
        case .imperial:
            // Glass 8oz, cup 12oz, bottle 16oz, large 24oz — stored as ml equivalents.
            return [("8 oz", 237), ("12 oz", 355), ("16 oz", 473), ("24 oz", 710)]
        }
    }

    /// "74.6 kg" (metric) or "164.5 lb" (imperial) — one decimal place.
    static func weightString(kg: Double, system: UnitSystem) -> String {
        switch system {
        case .metric:
            return String(format: "%.1f kg", kg)
        case .imperial:
            return String(format: "%.1f lb", pounds(fromKg: kg))
        }
    }

    /// "175 cm" (metric) or "5′9″" (imperial).
    static func heightString(cm: Double, system: UnitSystem) -> String {
        switch system {
        case .metric:
            return "\(Int(cm.rounded())) cm"
        case .imperial:
            let totalInches = cm / cmPerInch
            var feet = Int(totalInches / 12)
            var inches = Int((totalInches - Double(feet) * 12).rounded())
            if inches == 12 {
                feet += 1
                inches = 0
            }
            return "\(feet)′\(inches)″"
        }
    }

    static func kg(fromPounds pounds: Double) -> Double {
        pounds / poundsPerKg
    }

    static func pounds(fromKg kg: Double) -> Double {
        kg * poundsPerKg
    }
}
