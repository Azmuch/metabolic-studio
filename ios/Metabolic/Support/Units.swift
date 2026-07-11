import Foundation

/// Weight/height display + conversion helpers shared by onboarding, profile editing, and
/// the You tab. Storage always stays metric (kg/cm) — this only formats for display and
/// converts user-entered imperial values back to metric.
enum Units {
    private static let poundsPerKg = 2.20462
    private static let cmPerInch = 2.54

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
