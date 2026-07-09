# Metabolic — iOS Fitness & Nutrition App

A minimalist, dark-first fitness tracker for iPhone: calorie & water tracking, AI meal-photo
analysis, profile-driven daily workout plans with animated exercise illustrations, Yuka-style
product health scanning, three subscription tiers, and Apple Health sync.

<p>
<b>Today</b> · customizable widget dashboard &nbsp;|&nbsp;
<b>Nutrition</b> · diary, search, AI photo calories &nbsp;|&nbsp;
<b>Training</b> · generated plans + animated exercises &nbsp;|&nbsp;
<b>Scan</b> · barcode → 0-100 health score + alternatives &nbsp;|&nbsp;
<b>You</b> · profile, targets, membership, settings
</p>

## Requirements

- Xcode 16+ (project uses buildable-folder references), iOS 17.0+ deployment target
- No third-party dependencies — SwiftUI, SwiftData, StoreKit 2, HealthKit, VisionKit, Charts

## Getting started

1. Open `ios/Metabolic.xcodeproj` in Xcode.
2. Select your development team under *Signing & Capabilities* (HealthKit entitlement is
   pre-configured).
3. Run the `Metabolic` scheme on a device or simulator.
   - The scheme is pre-wired to `Config/Products.storekit`, so subscriptions are fully
     testable locally (Free → Plus → Pro).
   - **Demo mode is on by default** — the app seeds a week of realistic data and returns a
     canned AI meal analysis, so every screen is alive on first run. Toggle it off in
     *You → Settings*.

### Real AI meal analysis

Photo calorie estimation calls the Claude API directly. Add an Anthropic API key in
*You → Settings → AI*, turn off demo mode, and the camera/photo flow will estimate portion
sizes, calories and macros from a photo of your plate. (For App Store distribution, route
this through your own backend proxy instead of shipping user-entered keys.)

### Smart food scale

Pair a Bluetooth kitchen scale (standard GATT Weight Scale profile) under *You → Settings →
Devices*, or from the scale button inside any food-logging flow. Weigh a portion, tap
**Use N g**, and the grams flow straight into the entry — in the search flow the serving
multiplier is recalculated from the weighed amount automatically. A built-in **Demo Scale**
simulates readings so the flow works on the simulator and without hardware; vendor-specific
scale protocols can be added in `SmartScaleService`.

### Product scanning

Barcode scans hit the free [OpenFoodFacts](https://world.openfoodfacts.org) database. Scores
blend nutrition (60%, Nutri-Score point tables), additive risk (30%) and organic labeling
(10%) — with healthier same-category alternatives suggested for low scorers. On the
simulator (no camera) use the built-in manual barcode entry — try `3017620422003` (Nutella)
or `5449000000996` (Coca-Cola).

## Architecture

```
ios/
├── Metabolic.xcodeproj        # Xcode 16, folder-synchronized target
├── Metabolic/                 # app target — SwiftUI, SwiftData
│   ├── App/                   # entry point, root tabs, AppState
│   ├── DesignSystem/          # MTTheme tokens + shared components
│   ├── Features/              # Dashboard · Nutrition · Training · Scanner · Paywall · Onboarding · You
│   ├── Models/                # SwiftData @Model classes + demo seeder
│   └── Services/              # HealthKit, StoreKit 2, OpenFoodFacts, Claude vision, Keychain
├── MetabolicCore/             # local Swift package — pure domain logic, Linux-testable
│   ├── Sources/MetabolicCore/ # nutrition math, plan generator, exercise library + pose
│   │                          # keyframes, Yuka-style scoring, seed food DB, streaks
│   └── Tests/                 # XCTest suite (swift test)
├── Config/                    # HealthKit entitlements, StoreKit configuration
├── docs/                      # SPEC.md (product/engineering spec), INTERFACES.md
└── tools/verify_swift.py      # structural verifier (run from ios/)
```

**MetabolicCore** is Foundation-only so the whole domain layer — BMR/TDEE/macro targets
(Mifflin-St Jeor), the deterministic workout plan generator, MET calorie math, the
Nutri-Score-based product scoring engine, and the pose-keyframe data behind the exercise
animations — compiles and unit-tests anywhere: `cd ios/MetabolicCore && swift test`.

Exercise animations are rendered at runtime: each exercise ships normalized 13-joint pose
keyframes, interpolated with smoothstep easing in a `TimelineView`-driven `Canvas`
(`ExerciseAnimationView`) — no bundled video or GIF assets.

## Subscription tiers

| | Free | Plus | Pro |
|---|---|---|---|
| Logging, water, streaks, daily plan | ✓ | ✓ | ✓ |
| Barcode scans | 3/day | unlimited | unlimited |
| AI photo analysis | — | 30/mo | unlimited |
| Full exercise library + custom dashboard | — | ✓ | ✓ |
| Adaptive plans + CSV export | — | — | ✓ |

## Verification

```bash
cd ios
python3 tools/verify_swift.py --strict   # structural checks + contract audit
cd MetabolicCore && swift test           # domain engine unit tests (needs Swift toolchain)
```
