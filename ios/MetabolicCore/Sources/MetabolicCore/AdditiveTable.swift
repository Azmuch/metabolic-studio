import Foundation

public enum AdditiveRisk: Int, Codable, Comparable, Sendable {
    case none = 0, limited = 1, moderate = 2, high = 3

    public var displayName: String {
        switch self {
        case .none: return "No risk"
        case .limited: return "Limited risk"
        case .moderate: return "Moderate risk"
        case .high: return "High risk"
        }
    }

    public static func < (lhs: AdditiveRisk, rhs: AdditiveRisk) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum AdditiveTable {

    /// Lookup accepts "E330", "en:e330", " e330 " — case-insensitive, tag-prefix tolerant.
    /// Additives we don't know are treated as `.limited` (unknown ≠ safe, but ≠ proven risky).
    public static func risk(for eCode: String) -> AdditiveRisk {
        table[normalize(eCode)]?.risk ?? .limited
    }

    public static func name(for eCode: String) -> String {
        let key = normalize(eCode)
        return table[key]?.name ?? key.uppercased()
    }

    static func normalize(_ eCode: String) -> String {
        var code = eCode.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if code.hasPrefix("en:") { code = String(code.dropFirst(3)) }
        return code
    }

    private struct Entry {
        let risk: AdditiveRisk
        let name: String
    }

    private static let table: [String: Entry] = [
        // Colors
        "e100": Entry(risk: .none, name: "Curcumin"),
        "e101": Entry(risk: .none, name: "Riboflavin"),
        "e102": Entry(risk: .high, name: "Tartrazine"),
        "e104": Entry(risk: .high, name: "Quinoline Yellow"),
        "e110": Entry(risk: .high, name: "Sunset Yellow FCF"),
        "e120": Entry(risk: .moderate, name: "Cochineal (Carmine)"),
        "e122": Entry(risk: .high, name: "Azorubine"),
        "e124": Entry(risk: .high, name: "Ponceau 4R"),
        "e129": Entry(risk: .moderate, name: "Allura Red AC"),
        "e133": Entry(risk: .limited, name: "Brilliant Blue FCF"),
        "e150a": Entry(risk: .limited, name: "Plain Caramel"),
        "e150d": Entry(risk: .moderate, name: "Sulphite Ammonia Caramel"),
        "e160a": Entry(risk: .none, name: "Beta-Carotene"),
        "e160c": Entry(risk: .none, name: "Paprika Extract"),
        "e162": Entry(risk: .none, name: "Beetroot Red"),
        "e163": Entry(risk: .none, name: "Anthocyanins"),
        "e171": Entry(risk: .high, name: "Titanium Dioxide"),

        // Preservatives
        "e200": Entry(risk: .limited, name: "Sorbic Acid"),
        "e202": Entry(risk: .limited, name: "Potassium Sorbate"),
        "e211": Entry(risk: .moderate, name: "Sodium Benzoate"),
        "e220": Entry(risk: .moderate, name: "Sulphur Dioxide"),
        "e223": Entry(risk: .moderate, name: "Sodium Metabisulphite"),
        "e250": Entry(risk: .high, name: "Sodium Nitrite"),
        "e251": Entry(risk: .high, name: "Sodium Nitrate"),
        "e252": Entry(risk: .high, name: "Potassium Nitrate"),
        "e282": Entry(risk: .limited, name: "Calcium Propionate"),

        // Antioxidants & acids
        "e300": Entry(risk: .none, name: "Ascorbic Acid (Vitamin C)"),
        "e306": Entry(risk: .none, name: "Tocopherols (Vitamin E)"),
        "e320": Entry(risk: .moderate, name: "BHA"),
        "e321": Entry(risk: .moderate, name: "BHT"),
        "e322": Entry(risk: .none, name: "Lecithins"),
        "e330": Entry(risk: .none, name: "Citric Acid"),
        "e331": Entry(risk: .none, name: "Sodium Citrates"),
        "e338": Entry(risk: .moderate, name: "Phosphoric Acid"),

        // Thickeners, emulsifiers & stabilizers
        "e407": Entry(risk: .moderate, name: "Carrageenan"),
        "e412": Entry(risk: .limited, name: "Guar Gum"),
        "e415": Entry(risk: .limited, name: "Xanthan Gum"),
        "e420": Entry(risk: .limited, name: "Sorbitol"),
        "e433": Entry(risk: .moderate, name: "Polysorbate 80"),
        "e440": Entry(risk: .none, name: "Pectins"),
        "e450": Entry(risk: .moderate, name: "Diphosphates"),
        "e466": Entry(risk: .moderate, name: "Carboxymethylcellulose"),
        "e471": Entry(risk: .limited, name: "Mono- and Diglycerides"),
        "e472e": Entry(risk: .limited, name: "DATEM"),
        "e500": Entry(risk: .none, name: "Sodium Carbonates"),

        // Flavor enhancers
        "e621": Entry(risk: .moderate, name: "Monosodium Glutamate"),
        "e627": Entry(risk: .moderate, name: "Disodium Guanylate"),
        "e631": Entry(risk: .moderate, name: "Disodium Inosinate"),
        "e635": Entry(risk: .moderate, name: "Disodium Ribonucleotides"),

        // Glazing agents & waxes
        "e900": Entry(risk: .limited, name: "Dimethylpolysiloxane"),
        "e901": Entry(risk: .limited, name: "Beeswax"),
        "e903": Entry(risk: .limited, name: "Carnauba Wax"),
        "e920": Entry(risk: .limited, name: "L-Cysteine"),

        // Sweeteners
        "e950": Entry(risk: .moderate, name: "Acesulfame K"),
        "e951": Entry(risk: .high, name: "Aspartame"),
        "e952": Entry(risk: .moderate, name: "Cyclamates"),
        "e954": Entry(risk: .moderate, name: "Saccharin"),
        "e955": Entry(risk: .moderate, name: "Sucralose"),
        "e960": Entry(risk: .limited, name: "Steviol Glycosides"),
        "e961": Entry(risk: .moderate, name: "Neotame"),
        "e965": Entry(risk: .limited, name: "Maltitol"),
        "e967": Entry(risk: .limited, name: "Xylitol"),

        // Modified starches
        "e1400": Entry(risk: .limited, name: "Dextrin"),
        "e1442": Entry(risk: .limited, name: "Hydroxypropyl Distarch Phosphate"),
    ]
}
