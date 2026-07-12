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

## v2 highlights

- **US / metric units** toggle (weight in lb, height in ft/in — storage stays metric)
- **Flexibility & Mobility** training goal + optional **PT-style warm-up/cooldown blocks**
  built from an 11-move mobility library (functional-fitness ordering under the hood:
  compound squat/push/pull/hinge patterns lead every session)
- **Target areas**: pick muscle groups to strengthen/firm on an interactive body map
  (front/back diagram + custom deep-tissue flags; physician-consult guidance for
  anything persisting 3+ months)
- **Smart schedule**: pin days-per-week OR session length — the app recommends the other
  from your profile; custom equipment entries
- **Hypertrophy tracking**: optional per-set load logging, weekly volume + estimated
  sets-per-muscle breakdown
- **Meal prep**: deterministic weekly plan generator hitting your calorie/protein targets,
  one-tap meal logging, aggregated grocery list
- **Hand-portion guide**: sex-scaled palm/fist/cupped-hand/thumb quick logging
- **Coaching**: on-demand session player (sample HLS streams; swap in your studio's
  content) + live-session shell gated to Pro — gym/trainer integration comes later
- **Muscle-activation highlighting** on exercise animations + per-exercise muscle map
- **Accent themes** (Volt Lime / Tangerine / Earth / Jewel), **goals progress widget**,
  resting **heart-rate** from Apple Health, improved food search with custom-food fallback

## v3 highlights

- **Live theming without navigation resets** — accent switching now re-renders in place
  (observable `ThemeStore`), so you can compare themes without leaving Settings
- **Background styles**: Classic · Tinted (neutrals washed toward your accent) ·
  **Liquid Glass** (translucent cards over drifting accent light; uses the system
  glass treatment on iOS 26+) · **Photo** (your own wallpaper behind translucent cards)
- **Dietary preferences & allergies** — asked before the first meal plan is built
  (vegetarian/vegan/pescatarian + 7 allergens); plans strictly exclude flagged foods;
  editable in Edit Profile → Diet and from the Meal Prep toolbar
- **Anatomy heroes** — Higgsfield-generated écorché illustrations with activated
  muscles highlighted, crossfading into breathing loops in Exercise Detail and the
  session player; highlight color follows your accent theme. Run
  `bash ios/tools/fetch_anatomy_assets.sh` once (then commit) to bundle the artwork —
  until then the vector figures render as fallback. Front/back anatomy references
  appear in the body map once fetched.
- Animated attention cues on the hand-portions and smart-scale icons

Roadmap (needs assets/backend):
- **Rigged 3D exercise figure** — the target end-state for illustrations: a rigged
  androgynous USDZ base mesh with male/female morph targets, one skeletal animation
  clip per exercise id, and per-muscle-group materials tintable to the accent theme,
  rendered with SceneKit. `AnatomyHeroView` is already the swappable slot
  (3D → anatomy stills → vector fallback), so the model drops in without UI rework.
- Live trainer streaming backend; vendor-specific scale protocols.

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
