# Master exercise catalog for Seedance clip generation

Full generation target list for the local agent to run through Higgsfield/Seedance using
`SEEDANCE-PROMPT-KIT.md`. Covers functional fitness / CrossFit movements across weight
training, calisthenics, endurance/conditioning, and mobility — with beginner/intermediate/
advanced progressions named as distinct movements wherever a real progression exists (not
every movement needs three levels; single-level items are marked accordingly).

## Conventions

- **`clipId`** is the filename contract: `{clipId}.mp4` in `Metabolic/ExerciseClips/`, and
  (if promoted into the domain layer later) the `Exercise.id` in
  `MetabolicCore/Sources/MetabolicCore/ExerciseLibrary.swift`. camelCase, matches the existing
  37-exercise library's style.
- **Do not rename or regenerate `squat` or `pushUp`** — real clips already exist and are wired
  into the app. Everything else below is net-new.
- **Levels are separate named movements**, exactly like the existing library already does it
  (`kneePushUp` → `pushUp`, not `pushUpBeginner` → `pushUpAdvanced`). Where a progression has
  no natural 3rd tier (e.g. most static mobility holds), fewer than 3 are listed — don't invent
  a level that isn't a real distinct movement.
- **Prime movers** feed the Seedance prompt's `{TARGET MUSCLES}` field. **Neutral pose** feeds
  `{NEUTRAL POSE}` (the loop's start/end frame). Both are required per clip.
- **Category / Equipment / Muscle-group tags** use the app's existing enums (`ExerciseCategory`
  {strength, mobility}; `Equipment` {none, dumbbells, resistanceBands, kettlebell, barbell,
  pullUpBar, bench, fullGym}; `MuscleGroup` {chest, back, shoulders, arms, core, quads,
  hamstrings, glutes, calves, fullBody, cardio}) so any of these can be promoted straight into
  `ExerciseLibrary.swift` later without a schema change. "Bucket" (Weight Training /
  Calisthenics / Endurance / Mobility) is the content-team organizing label from the brief —
  it's not an app enum; endurance and calisthenics both map to `category: .strength`.
- **✓ in library** = already in `ExerciseLibrary.swift` (37 items) — generation only, no new
  `Exercise` entry needed. Everything else needs both a clip and (eventually) a library entry.

## Suggested generation priority

1. Complete the progressions for movements already in the library (squat, push-up, pull-up,
   lunge, plank, deadlift-pattern) — these unlock levels for existing users immediately.
2. Foundational functional-fitness movements (Sections A–C "Intermediate" rows) — the core
   CrossFit/functional vocabulary.
3. Beginner regressions (accessibility, lower barrier to entry).
4. Advanced/skill movements (retention, Pro-tier differentiation).
5. Mobility (Section D) — high volume, cheap/fast to generate, good for warm-up/cooldown coverage.

---

## A. Weight Training (barbell / dumbbell / kettlebell)

### A1. Squat pattern
| Level | clipId | Name | Equipment | Prime movers | Neutral pose |
|---|---|---|---|---|---|
| Beginner | `boxSquat` | Box Squat | bench | quads, glutes | standing, box behind knees |
| Intermediate | `gobletSquat` ✓ | Goblet Squat | dumbbells/kettlebell | quads, glutes | standing, weight at chest |
| Intermediate | `backSquat` | Back Squat | barbell/fullGym | quads, glutes | standing, bar racked on traps |
| Advanced | `frontSquat` | Front Squat | barbell/fullGym | quads, glutes, core | standing, bar racked on delts |
| Advanced | `overheadSquat` | Overhead Squat | barbell/fullGym | quads, glutes, shoulders, core | standing, bar locked overhead |

### A2. Hinge / deadlift pattern
| Level | clipId | Name | Equipment | Prime movers | Neutral pose |
|---|---|---|---|---|---|
| Beginner | `hipHinge` | Hip Hinge Drill | none | hamstrings, glutes | standing tall, hands on hips |
| Intermediate | `dbRomanianDeadlift` ✓ | Dumbbell Romanian Deadlift | dumbbells | hamstrings, glutes, back | standing, dumbbells at thighs |
| Intermediate | `kettlebellDeadlift` | Kettlebell Deadlift | kettlebell | hamstrings, glutes, back | standing, kettlebell on floor between feet |
| Advanced | `conventionalDeadlift` | Conventional Deadlift | barbell/fullGym | hamstrings, glutes, back | standing, bar over midfoot |
| Advanced | `sumoDeadlift` | Sumo Deadlift | barbell/fullGym | glutes, quads, back | wide stance, bar over midfoot |

### A3. Press pattern
| Level | clipId | Name | Equipment | Prime movers | Neutral pose |
|---|---|---|---|---|---|
| Beginner | `dbShoulderPress` ✓ | Dumbbell Shoulder Press | dumbbells | shoulders, arms | standing, dumbbells at shoulders |
| Intermediate | `pushPress` | Push Press | barbell/fullGym | shoulders, arms, quads | standing, bar racked at shoulders |
| Intermediate | `benchPress` | Bench Press | bench, barbell/fullGym | chest, shoulders, arms | lying on bench, bar at chest |
| Advanced | `pushJerk` | Push Jerk | barbell/fullGym | shoulders, arms, quads, core | standing, bar racked at shoulders |
| Advanced | `splitJerk` | Split Jerk | barbell/fullGym | shoulders, arms, quads, core | standing, bar racked at shoulders |

### A4. Olympic lifts (advanced only — no natural beginner/intermediate bodyweight regression)
| Level | clipId | Name | Equipment | Prime movers | Neutral pose |
|---|---|---|---|---|---|
| Intermediate | `hangCleanFromKnee` | Hang Clean (from knee) | barbell/fullGym | hamstrings, glutes, back, shoulders | standing, bar at knee |
| Advanced | `powerClean` | Power Clean | barbell/fullGym | fullBody | standing, bar over midfoot |
| Advanced | `cleanAndJerk` | Clean and Jerk | barbell/fullGym | fullBody | standing, bar over midfoot |
| Advanced | `powerSnatch` | Power Snatch | barbell/fullGym | fullBody | standing, wide grip, bar over midfoot |

### A5. Row / pull pattern
| Level | clipId | Name | Equipment | Prime movers | Neutral pose |
|---|---|---|---|---|---|
| Beginner | `bandRow` ✓ | Band Row | resistanceBands | back, arms | seated, band anchored at feet |
| Intermediate | `dbRow` ✓ | Dumbbell Row | dumbbells, bench | back, arms | half-kneeling, one hand + knee on bench |
| Intermediate | `pendlayRow` | Pendlay Row | barbell/fullGym | back, arms | hinged over, bar on floor |
| Advanced | `barbellRow` | Barbell Bent-Over Row | barbell/fullGym | back, arms | hinged over, bar at thighs |

### A6. Kettlebell / functional complexes
| Level | clipId | Name | Equipment | Prime movers | Neutral pose |
|---|---|---|---|---|---|
| Beginner | `kettlebellDeadliftSwing` | Dead-Stop KB Swing | kettlebell | glutes, hamstrings, core | standing, kettlebell on floor |
| Intermediate | `kbSwing` ✓ | Kettlebell Swing | kettlebell | glutes, hamstrings, core | standing, kettlebell between legs |
| Advanced | `kbSnatch` | Kettlebell Snatch | kettlebell | fullBody | standing, kettlebell between legs |
| Advanced | `turkishGetUp` | Turkish Get-Up | kettlebell | fullBody | lying on back, kettlebell locked overhead |

### A7. Lunge pattern
| Level | clipId | Name | Equipment | Prime movers | Neutral pose |
|---|---|---|---|---|---|
| Beginner | `reverseLunge` | Reverse Lunge | none | quads, glutes | standing, feet together |
| Intermediate | `lunge` ✓ | Forward Lunge | none | quads, glutes | standing, feet together |
| Intermediate | `walkingLunge` | Walking Lunge | none/dumbbells | quads, glutes | standing, feet together |
| Advanced | `bulgarianSplitSquat` | Bulgarian Split Squat | bench | quads, glutes | standing, rear foot on bench |

### A8. Carries and accessories (single-level)
| clipId | Name | Equipment | Prime movers | Neutral pose |
|---|---|---|---|---|
| `farmersCarry` | Farmer's Carry | dumbbells/kettlebell | fullBody, core | standing, weights at sides |
| `dbCurl` ✓ | Dumbbell Curl | dumbbells | arms | standing, dumbbells at thighs |
| `lateralRaise` ✓ | Lateral Raise | dumbbells | shoulders | standing, dumbbells at sides |
| `calfRaise` ✓ | Calf Raise | none | calves | standing, feet flat |
| `manMaker` | Man Maker | dumbbells | fullBody | standing, dumbbells on floor |
| `thruster` | Thruster | dumbbells/barbell | fullBody | standing, weight racked at shoulders |

---

## B. Calisthenics / Gymnastics

### B1. Push-up pattern
| Level | clipId | Name | Equipment | Prime movers | Neutral pose |
|---|---|---|---|---|---|
| Beginner | `kneePushUp` ✓ | Knee Push-Up | none | chest, arms | top plank, knees down |
| Intermediate | `pushUp` ✓ | Push-Up | none | chest, arms | top plank |
| Advanced | `archerPushUp` | Archer Push-Up | none | chest, arms | top plank, wide hands |
| Advanced | `deficitPushUp` | Deficit Push-Up | dumbbells/bench | chest, arms | top plank, hands elevated |

### B2. Pull-up pattern
| Level | clipId | Name | Equipment | Prime movers | Neutral pose |
|---|---|---|---|---|---|
| Beginner | `ringRow` | Ring Row | pullUpBar | back, arms | hanging under bar, body angled, arms extended |
| Intermediate | `pullUp` ✓ | Pull-Up | pullUpBar | back, arms | dead hang |
| Advanced | `chestToBarPullUp` | Chest-to-Bar Pull-Up | pullUpBar | back, arms | dead hang |
| Advanced | `muscleUp` | Muscle-Up | pullUpBar | back, arms, chest | dead hang |

### B3. Dip pattern
| Level | clipId | Name | Equipment | Prime movers | Neutral pose |
|---|---|---|---|---|---|
| Beginner | `benchDip` | Bench Dip | bench | arms, chest | seated on edge, hands on bench, legs extended |
| Intermediate | `barDip` | Bar Dip | pullUpBar/fullGym | arms, chest | top support, arms locked |
| Advanced | `ringDip` | Ring Dip | fullGym | arms, chest, shoulders | top support, arms locked |

### B4. Squat calisthenics
| Level | clipId | Name | Equipment | Prime movers | Neutral pose |
|---|---|---|---|---|---|
| Beginner | `squat` ✓ | Bodyweight/Air Squat | none | quads, glutes | standing |
| Intermediate | `jumpSquat` | Jump Squat | none | quads, glutes | standing |
| Advanced | `pistolSquat` | Pistol Squat | none | quads, glutes, core | standing on one leg, other leg extended forward |

### B5. Core
| Level | clipId | Name | Equipment | Prime movers | Neutral pose |
|---|---|---|---|---|---|
| Beginner | `deadBug` ✓ | Dead Bug | none | core | lying on back, arms up, knees at 90° |
| Beginner | `kneePlank` | Knee Plank | none | core | forearm plank, knees down |
| Intermediate | `plank` ✓ | Plank | none | core | forearm plank |
| Intermediate | `sidePlank` ✓ | Side Plank | none | core | side forearm plank |
| Intermediate | `vUp` | V-Up | none | core | lying flat, arms overhead |
| Advanced | `hollowHold` | Hollow Rock Hold | none | core | lying on back, shoulders + legs lifted |
| Advanced | `toesToBar` | Toes-to-Bar | pullUpBar | core, back | dead hang |
| Advanced | `lSit` | L-Sit | fullGym | core, arms | supported on parallettes/floor, legs extended forward |

### B6. Handstand progression
| Level | clipId | Name | Equipment | Prime movers | Neutral pose |
|---|---|---|---|---|---|
| Beginner | `pikePushUp` | Pike Push-Up | none | shoulders, arms | pike position, hands on floor |
| Intermediate | `wallHandstandHold` | Wall Handstand Hold | none | shoulders, core | inverted against wall |
| Advanced | `handstandPushUp` | Handstand Push-Up | none | shoulders, arms, core | inverted against wall |

### B7. Jump / power (single-level unless noted)
| clipId | Name | Equipment | Prime movers | Neutral pose |
|---|---|---|---|---|
| `burpee` ✓ | Burpee | none | fullBody | standing |
| `halfBurpee` (beginner) | Half Burpee (step-back, no push-up) | none | fullBody | standing |
| `burpeeBoxJumpOver` (advanced) | Burpee Box Jump Over | bench | fullBody | standing next to box |
| `stepUp` (beginner) | Box Step-Up | bench | quads, glutes | standing facing box |
| `boxJump` (intermediate) | Box Jump | bench | quads, glutes | standing facing box |
| `broadJump` | Broad Jump | none | quads, glutes | standing |

---

## C. Endurance / Monostructural / Conditioning (single-level unless noted)

| clipId | Name | Equipment | Prime movers | Neutral pose |
|---|---|---|---|---|
| `jumpingJack` ✓ | Jumping Jack | none | fullBody, cardio | standing, arms at sides |
| `highKnees` ✓ | High Knees | none | quads, cardio | standing |
| `mountainClimber` ✓ | Mountain Climber | none | core, cardio | top plank |
| `jumpRope` | Jump Rope | none | calves, cardio | standing, knees soft |
| `doubleUnder` (advanced) | Double Under | none | calves, cardio | standing, knees soft |
| `sledPush` | Sled Push | fullGym | fullBody, cardio | low athletic stance, hands on sled |
| `sledPull` | Sled Pull | fullGym | back, cardio | standing, rope in hands |
| `rowErg` | Rowing (Erg) | fullGym | back, quads, cardio | seated, arms extended, knees bent |
| `airBike` | Assault Bike | fullGym | fullBody, cardio | seated, hands on handles |
| `battleRopes` | Battle Ropes | fullGym | shoulders, arms, cardio | athletic stance, rope ends in hands |
| `sprintInPlace` | Sprint in Place | none | quads, cardio | standing, athletic stance |

---

## D. Mobility

Already covered (11 items ✓): `ankleCircles`, `calfStretch`, `catCow`, `childsPose`,
`figureFourStretch`, `hamstringStretch`, `hipFlexorStretch`, `neckRelease`, `shoulderCircles`,
`thoracicRotation`, `worldsGreatestStretch`.

New (single-level — static holds rarely have a real 3-tier progression; a couple do, noted):

| Level | clipId | Name | Prime target | Neutral pose |
|---|---|---|---|---|
| — | `ninetyNinetyHipStretch` | 90/90 Hip Stretch | hip | seated, front leg bent 90°, back leg bent 90° |
| Beginner | `assistedCossackSquat` | Assisted Cossack Squat | hip, quads | wide stance, holding support |
| Advanced | `cossackSquat` | Cossack Squat | hip, quads | wide stance |
| — | `threadTheNeedle` | Thread the Needle | shoulders, back | quadruped |
| — | `cobraStretch` | Cobra Stretch | core, back | lying face down, hands under shoulders |
| — | `pigeonPose` | Pigeon Pose | hip | quadruped, one shin forward |
| — | `quadStretch` | Standing Quad Stretch | quads | standing, holding one foot behind |
| — | `wristMobility` | Wrist Mobility Flow | wrist | kneeling, hands on floor |
| — | `scapularWallSlide` | Scapular Wall Slide | shoulders, back | standing against wall, arms at 90° |
| — | `deepSquatHold` | Deep Squat Hold (Frog Stretch) | hip, ankle | bottom of squat |
| — | `spinalTwist` | Seated Spinal Twist | back | seated, legs extended |
| — | `ankleDorsiflexionStretch` | Ankle Dorsiflexion Stretch | ankle | half-kneeling, front knee over toe |

---

## Summary counts

- Already in library, generation-only: **13** (squat, pushUp already have clips; +11 more)
- Net-new movements defined above: **~64**
- Total catalog: **~77 distinct clips**, covering full beginner→advanced progressions for every
  major functional-fitness pattern (squat, hinge, press, pull, lunge, push-up, dip, core,
  handstand) plus Olympic lifts, carries, monostructural conditioning, and mobility.

Hand this file to the local agent alongside `SEEDANCE-PROMPT-KIT.md`: for each row, fill the
prompt template's `{EXERCISE}`, `{EXPERT FORM DESCRIPTION}` (add to the kit's form-description
library as each is authored), `{NEUTRAL POSE}`, and `{TARGET MUSCLES}` from this table.

---

# Add-on discipline sets (E–I)

These five are **class-oriented add-ons**, distinct from the functional-fitness core above.
Two content types live here, and they must not be conflated:

- **Individual-move clips** (yoga asanas, pilates moves, kickboxing strikes, signature HIIT
  moves): 4s écorché loops, same pipeline as the core catalog, and they can feed the exercise
  library. Listed with `clipId`s below.
- **Full guided sessions** (sun-salutation flows, pilates mat classes, HIIT circuits,
  kickboxing rounds, every meditation): **10–45 min instructor-led content**, NOT 4s loops.
  These belong to the Coaching / live-stream shell (`CoachingView`), not `ExerciseLibrary`.
  A 4s anatomical loop is a *reference*, never a follow-along class — see the critique.

The écorché figure is also the wrong medium for yoga/meditation brand-wise (clinical, not
calming). For those, plan a warmer human/ambient visual treatment rather than the muscle figure.

## E. Yoga

**Asanas (individual clips):**
| Level | clipId | Name | Prime target | Neutral pose |
|---|---|---|---|---|
| Beginner | `mountainPose` | Mountain Pose (Tadasana) | fullBody | standing tall, arms at sides |
| Beginner | `downwardDog` | Downward-Facing Dog | shoulders, hamstrings | inverted V, hands + feet on floor |
| Beginner | `bridgePose` | Bridge Pose | glutes, core | lying on back, knees bent |
| Beginner | `seatedForwardFold` | Seated Forward Fold | hamstrings, back | seated, legs extended |
| Intermediate | `warrior1` | Warrior I | quads, glutes | standing, feet split, arms overhead |
| Intermediate | `warrior2` | Warrior II | quads, glutes | standing, feet wide, arms extended |
| Intermediate | `warrior3` | Warrior III | glutes, hamstrings, core | standing on one leg, torso + rear leg parallel to floor |
| Intermediate | `trianglePose` | Triangle Pose | core, hamstrings | standing, feet wide, arms extended |
| Intermediate | `chairPose` | Chair Pose | quads, glutes | standing, arms overhead |
| Intermediate | `treePose` | Tree Pose | core, calves | standing on one leg, foot to inner thigh |
| Advanced | `crowPose` | Crow Pose | shoulders, core, arms | crouched, hands on floor |
| Advanced | `wheelPose` | Wheel Pose | back, shoulders | lying on back, hands + feet planted |
| Advanced | `dancerPose` | Dancer's Pose | quads, core | standing on one leg, holding rear foot |

**Flows (classes — session content, not clips):** `sunSalutationA`, `sunSalutationB`,
`vinyasaFlow`, `yinYoga`, `restorativeYoga`, `powerYoga` — each in beginner/intermediate/advanced
lengths.

## F. Pilates

**Mat moves (individual clips):**
| Level | clipId | Name | Prime target | Neutral pose |
|---|---|---|---|---|
| Beginner | `pilatesHundred` | The Hundred | core | lying on back, legs at tabletop |
| Beginner | `pelvicCurl` | Pelvic Curl | glutes, core | lying on back, knees bent |
| Beginner | `singleLegStretch` | Single-Leg Stretch | core | lying on back, head + shoulders lifted |
| Beginner | `legCircles` | Leg Circles | core, hip | lying on back, one leg extended up |
| Intermediate | `rollUp` | Roll-Up | core | lying flat, arms overhead |
| Intermediate | `crissCross` | Criss-Cross | core | lying on back, hands behind head |
| Intermediate | `sawStretch` | The Saw | core, hamstrings | seated, legs wide, arms extended |
| Intermediate | `swanDive` | Swan Dive | back, glutes | lying face down, hands under shoulders |
| Intermediate | `sidekickSeries` | Side-Kick Series | glutes, core | lying on side, legs stacked |
| Advanced | `teaser` | The Teaser | core | lying flat, arms overhead |
| Advanced | `boomerang` | The Boomerang | core | seated, legs crossed + extended |
| Advanced | `jackknife` | Jackknife | core | lying on back, legs extended up |

**Classes:** `pilatesMatBeginner/Intermediate/Advanced`, `pilatesCore`, `pilatesFullBody`.

## G. HIIT

HIIT is a **format** (work/rest intervals), not a muscle group — most classes reuse the core
functional catalog on a Tabata/EMOM/AMRAP clock. A few signature moves are net-new clips:

| Level | clipId | Name | Prime target | Neutral pose |
|---|---|---|---|---|
| Beginner | `plankJack` | Plank Jack | core, cardio | forearm/high plank |
| Intermediate | `skaterJump` | Skater Jump | quads, glutes, cardio | athletic stance |
| Intermediate | `squatThrust` | Squat Thrust (no push-up) | fullBody, cardio | standing |
| Intermediate | `sprawl` | Sprawl | fullBody, cardio | athletic stance |
| Advanced | `tuckJump` | Tuck Jump | quads, cardio | standing, knees soft |
| Advanced | `starJump` | Star Jump | fullBody, cardio | crouched |

**Class templates (session content):** `tabata20x10`, `emom`, `amrap`, `hiit30`, `hiit45` —
timed circuits assembled from these + the core catalog. Build as a circuit-timer session type.

## H. Kickboxing

**Strikes / kicks (individual clips — new movement family):**
| Level | clipId | Name | Prime target | Neutral pose |
|---|---|---|---|---|
| Beginner | `jab` | Jab | shoulders, arms, core | boxing stance, guard up |
| Beginner | `cross` | Cross | shoulders, arms, core | boxing stance, guard up |
| Beginner | `frontKick` | Front (Teep) Kick | quads, core | boxing stance, guard up |
| Intermediate | `hook` | Hook | shoulders, arms, core | boxing stance, guard up |
| Intermediate | `uppercut` | Uppercut | shoulders, arms, core | boxing stance, guard up |
| Intermediate | `roundhouseKick` | Roundhouse Kick | glutes, quads, core | boxing stance, guard up |
| Intermediate | `kneeStrike` | Knee Strike | quads, core | boxing stance, guard up |
| Advanced | `sideKick` | Side Kick | glutes, quads, core | boxing stance, guard up |
| Advanced | `bobAndWeave` | Bob and Weave (defense) | core, quads | boxing stance, guard up |
| Advanced | `spinningBackKick` | Spinning Back Kick | glutes, core | boxing stance, guard up |

**Classes:** `shadowboxRound`, `kickboxHIIT`, `heavyBagRound` (needs a bag prop in the clip) —
3-minute rounds, combo-driven.

## I. Meditation & Breathwork (AUDIO / ambient — NOT movement clips)

These have **no Seedance movement clip**. They need guided **audio** (narrator voice + ambient
bed) plus a calm ambient visual (a slow gradient, breathing orb, or generated nature loop — not
the écorché figure). Different production pipeline entirely (voice generation + audio, e.g.
ElevenLabs/Higgsfield audio; the app plays audio with a minimal visual).

| sessionId | Name | Length | Type |
|---|---|---|---|
| `boxBreathing` | Box Breathing | 3–5 min | breathwork, animated breathing guide |
| `478Breathing` | 4-7-8 Breathing | 3–5 min | breathwork, animated breathing guide |
| `bodyScan` | Body Scan | 10–20 min | guided audio |
| `focusMeditation` | Focus / Pre-Workout | 5–10 min | guided audio |
| `sleepMeditation` | Sleep / Wind-Down | 15–30 min | guided audio |
| `morningMeditation` | Morning Intention | 5–10 min | guided audio |
| `lovingKindness` | Loving-Kindness | 10–15 min | guided audio |
| `stressReset` | Stress Reset | 5 min | guided audio |

## Add-on summary

- Yoga: 13 asana clips + 6 flow classes
- Pilates: 12 mat-move clips + 5 classes
- HIIT: 6 signature clips + 5 class templates (reuses core catalog)
- Kickboxing: 10 strike/kick clips + 3 round classes
- Meditation: 8 audio sessions (no movement clips)

**~41 new movement clips + ~27 guided sessions** on top of the ~77-clip core catalog. The
guided sessions are the Apple Fitness+-style content and are a fundamentally larger production
effort than the clips — see the critique before committing to producing them in-house.
