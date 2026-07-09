import SwiftUI

/// Subscription tier ordering: Free < Plus < Pro. `Comparable` is hand-rolled since raw-value
/// synthesis only covers `Equatable`/`Hashable`.
enum SubscriptionTier: Int, Codable, Comparable, CaseIterable {
    case free = 0
    case plus = 1
    case pro = 2

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .plus: return "Plus"
        case .pro: return "Pro"
        }
    }

    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Capabilities gated behind a subscription tier.
enum Feature: String, CaseIterable {
    case aiPhotoAnalysis
    case unlimitedScans
    case dashboardCustomize
    case fullExerciseLibrary
    case adaptivePlans
    case dataExport
}

/// Maps gated features to the minimum tier that unlocks them.
enum FeatureGate {
    static func minTier(for feature: Feature) -> SubscriptionTier {
        switch feature {
        case .aiPhotoAnalysis, .unlimitedScans, .dashboardCustomize, .fullExerciseLibrary:
            return .plus
        case .adaptivePlans, .dataExport:
            return .pro
        }
    }

    static func allows(_ feature: Feature, tier: SubscriptionTier) -> Bool {
        tier >= minTier(for: feature)
    }
}
