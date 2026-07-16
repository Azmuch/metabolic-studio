# NB-Pro grid prompts — écorché core catalog (A–D)

Ready-to-run keyframe prompts for the **validated grid pipeline** (see
`SEEDANCE-PROMPT-KIT.md` v4). One 1:1 two-panel grid per exercise → split → upload → Seedance.
Scope = écorché functional-fitness core (A–D). E–I (yoga/pilates/HIIT/kickboxing/meditation)
are held for the warmer visual treatment and are **not** here.

## How to expand each row

Every row gives only the variables. Wrap them in the two fixed templates:

**GRID (Nano Banana Pro — `nano_banana_2`, `aspect_ratio:"1:1"`, `resolution:"2k"`):**
> `<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>>` A clean two-panel side-by-side reference on a
> plain white background. ONE single consistent figure in BOTH panels at the EXACT same body
> scale and proportions, **{CAM}**, same ground line and same distance from camera. A thin
> vertical gap splits the image down the exact center into a LEFT and a RIGHT panel.
> LEFT panel: **{START}**. RIGHT panel: the SAME figure **{PEAK}**; **{MUSCLES}** glow bright
> green. Whole body head-to-toe fully in frame in each panel, never cropped, feet and head never
> touching the panel edges.

**SEEDANCE (`seedance_2_0`, start=left panel, end=right panel, `9:16`, `duration:4`,
`generate_audio:false`):**
> The figure demonstrates one **{NAME}** with correct textbook functional-fitness / CrossFit
> form and technique. 0:00–0:02 it moves from {start} into the {peak}; 0:02–0:04 it
> **{HOLD or RETURN}**. Locked static camera, plain white background. No music, no sound, no audio.

- **HOLD** clips: 0:02–0:04 "holds, perfectly still." → manifest `type:"hold"`.
- **REP** clips: 0:02–0:04 "returns to the start." → manifest `type:"rep"` (app ping-pongs A→B).
- **CAM** default `side-profile camera at standing height`; floor moves use `side-profile camera
  at floor level`; symmetric frontal moves use `front-on camera, figure facing the camera`.
- If a run shows the green washing out, add "core stays glowing green" to the Seedance line.
- Ballistic moves (jumps, Olympic lifts, KB swing, burpee) are marked **⚡ full-motion**: do NOT
  ping-pong (asymmetric); generate at natural tempo, longer if needed, and trim in app.

`✓DONE` = clip already in `ExerciseClips/`. `⏭existing` = already wired in app, don't regenerate.

---

## A1. Squat pattern  (CAM: side-profile, standing height)

| clipId | type | START (left) | PEAK (right) + green | notes |
|---|---|---|---|---|
| `boxSquat` ✓DONE | rep | standing tall, a low box just behind the heels | seated back onto the box, shins vertical, hips below knees; **quads, glutes** | |
| `gobletSquat` ✓DONE | rep | standing, both hands cupping a kettlebell at the chest | bottom of a squat, elbows inside knees, torso tall; **quads, glutes** | |
| `backSquat` | rep | standing, a barbell racked across the upper back/traps | below-parallel squat, bar path over midfoot, torso braced; **quads, glutes** | |
| `frontSquat` ✓DONE | rep | standing, barbell racked on the FRONT delts, elbows high | below-parallel squat, elbows stay high, torso upright; **quads, glutes, core** | re-check: bar on front |
| `overheadSquat` | rep | standing, barbell locked overhead, arms straight, wide grip | full-depth squat, bar still locked overhead over midfoot; **quads, glutes, shoulders, core** | |

## A2. Hinge / deadlift pattern  (CAM: side-profile, standing height)

| clipId | type | START (left) | PEAK (right) + green | notes |
|---|---|---|---|---|
| `hipHinge` | rep | standing tall, hands on hips | hinged at the hips, flat back near parallel, soft knees; **hamstrings, glutes** | |
| `kettlebellDeadlift` | rep | standing, a kettlebell on the floor between the feet | standing lockout holding the kettlebell, hips extended, flat back through the pull; **hamstrings, glutes, back** | |
| `conventionalDeadlift` | rep | bar over midfoot, shins to bar, flat back, arms straight (bottom) | tall lockout, hips and knees extended, shoulders back; **hamstrings, glutes, back** | |
| `sumoDeadlift` | rep | wide stance, bar over midfoot, hands inside knees, flat back (bottom) | tall lockout, hips forward, knees out; **glutes, quads, back** | |

## A3. Press pattern  (CAM: side-profile, standing height; benchPress floor level)

| clipId | type | START (left) | PEAK (right) + green | notes |
|---|---|---|---|---|
| `pushPress` ⚡ | rep | standing, barbell racked at the shoulders, slight knee dip | bar locked out overhead, arms straight, ribs down; **shoulders, arms, quads** | dip-drive |
| `benchPress` | rep | lying on a flat bench, barbell at the chest, elbows ~45° (CAM floor level) | bar pressed to straight-arm lockout over the chest; **chest, shoulders, arms** | |
| `pushJerk` ⚡ | rep | standing, barbell racked at shoulders, dip | bar locked overhead, brief re-bend then stand; **shoulders, arms, quads, core** | full-motion |
| `splitJerk` ⚡ | rep | standing, barbell racked at shoulders, dip | bar locked overhead in a split-leg stance, one foot forward; **shoulders, arms, quads, core** | full-motion |

## A4. Olympic lifts  (CAM: side-profile, standing height — ⚡ all full-motion, no ping-pong)

| clipId | type | START (left) | PEAK (right) + green | notes |
|---|---|---|---|---|
| `hangCleanFromKnee` ⚡ | rep | standing, barbell held at the knees, flat back | barbell caught racked on the front shoulders, elbows high, quarter squat; **hamstrings, glutes, back, shoulders** | |
| `powerClean` ⚡ | rep | barbell over midfoot on the floor, flat-back setup | bar caught on the front shoulders in a partial squat, elbows high; **fullBody** | |
| `cleanAndJerk` ⚡ | rep | barbell over midfoot on the floor | bar locked overhead after a front-rack clean into a split jerk; **fullBody** | 2-beat; longer duration |
| `powerSnatch` ⚡ | rep | barbell on floor, wide snatch grip, flat-back setup | bar caught locked overhead in a partial squat, wide grip; **fullBody** | |

## A5. Row / pull pattern  (CAM: side-profile, standing height)

| clipId | type | START (left) | PEAK (right) + green | notes |
|---|---|---|---|---|
| `pendlayRow` | rep | hinged over ~parallel, barbell resting on the floor, arms straight | bar pulled explosively to the lower ribs, elbows high, back flat | **back, arms** |
| `barbellRow` | rep | hinged over ~45°, barbell at the thighs, arms straight | bar pulled to the waist, elbows past the ribs; **back, arms** | |

## A6. Kettlebell / functional  (CAM: side-profile, standing height)

| clipId | type | START (left) | PEAK (right) + green | notes |
|---|---|---|---|---|
| `kettlebellDeadliftSwing` ⚡ | rep | standing, kettlebell on the floor between the feet | kettlebell swung to chest height, arms straight, hips snapped through; **glutes, hamstrings, core** | dead-stop |
| `kbSnatch` ⚡ | rep | standing, kettlebell between the legs, one hand | kettlebell locked overhead, arm straight; **fullBody** | full-motion |
| `turkishGetUp` ⚡ | rep | lying on back, kettlebell pressed straight up in one hand (CAM floor level) | standing tall, kettlebell locked overhead; **fullBody** | long; longer duration |

## A7. Lunge pattern  (CAM: side-profile, standing height)

| clipId | type | START (left) | PEAK (right) + green | notes |
|---|---|---|---|---|
| `reverseLunge` ✓DONE | rep | standing, feet together | rear leg stepped back into a lunge, both knees ~90°, front shin vertical; **quads, glutes** | |
| `walkingLunge` ✓DONE | rep | standing, feet together | forward lunge, both knees ~90°, front shin vertical, torso tall; **quads, glutes** | |
| `bulgarianSplitSquat` ✓DONE | rep | standing, rear foot laced on a bench behind | front thigh to parallel, torso tall, rear knee dropping; **quads, glutes** | |

## A8. Carries & accessories  (CAM: side-profile, standing height; lateralRaise front-on)

| clipId | type | START (left) | PEAK (right) + green | notes |
|---|---|---|---|---|
| `farmersCarry` | hold | standing tall, a heavy dumbbell in each hand at the sides | mid-stride carry, one foot forward, weights steady at sides, braced; **fullBody, core** | |
| `manMaker` ⚡ | rep | standing, a dumbbell on the floor in each hand | overhead lockout after a burpee-row-clean sequence; **fullBody** | full-motion |
| `thruster` ⚡ | rep | front-rack squat bottom, weight at the shoulders | weight locked overhead, hips and arms fully extended; **fullBody** | squat-to-press |

---

## B1. Push-up pattern  (CAM: side-profile, floor level)

| clipId | type | START (left) | PEAK (right) + green | notes |
|---|---|---|---|---|
| `kneePushUp` ✓DONE | rep | top plank on the knees, arms straight | chest lowered near the floor, elbows ~45°, knees down; **chest, arms** | re-check knees-down |
| `archerPushUp` | rep | wide-hand top plank, arms straight | chest lowered to one hand, that elbow bent, other arm straight; **chest, arms** | |
| `deficitPushUp` | rep | top plank, hands on low blocks (elevated) | chest dropped below hand level, deep stretch, elbows ~45°; **chest, arms** | |

## B2. Pull-up pattern  (CAM: side-profile / front-on, standing height, bar in frame top)

| clipId | type | START (left) | PEAK (right) + green | notes |
|---|---|---|---|---|
| `ringRow` | rep | hanging under rings, body angled, arms extended, heels on floor | chest pulled to the rings, elbows back, body straight; **back, arms** | |
| `chestToBarPullUp` | rep | dead hang from a bar, arms straight | pulled up until the chest touches the bar; **back, arms** | |
| `muscleUp` ⚡ | rep | dead hang from a bar | transitioned to a straight-arm support above the bar; **back, arms, chest** | full-motion |

## B3. Dip pattern  (CAM: side-profile, standing height)

| clipId | type | START (left) | PEAK (right) + green | notes |
|---|---|---|---|---|
| `benchDip` | rep | seated on a bench edge, hands on bench, legs extended, hips off | hips lowered, elbows ~90° behind; **arms, chest** | |
| `barDip` | rep | top support on parallel bars, arms locked | lowered, elbows ~90°, slight forward lean; **arms, chest** | |
| `ringDip` | rep | top support on rings, arms locked, rings turned out | lowered under control, elbows ~90°, rings tight; **arms, chest, shoulders** | |

## B4. Squat calisthenics  (CAM: side-profile, standing height)

| clipId | type | START (left) | PEAK (right) + green | notes |
|---|---|---|---|---|
| `jumpSquat` ⚡ | rep | standing | peak of a vertical jump, feet off floor, arms driving up; **quads, glutes** | full-motion |
| `pistolSquat` | rep | standing on one leg, other leg extended forward off the floor | full one-leg squat, hips to the heel, free leg out front; **quads, glutes, core** | |

## B5. Core  (CAM: side-profile, floor level)

| clipId | type | START (left) | PEAK (right) + green | notes |
|---|---|---|---|---|
| `kneePlank` | hold | lying face-down, forearms under shoulders, knees down | forearm plank on the knees, straight line knees-to-head; **core** | |
| `plank` ✓DONE | hold | lying face-down, forearms under shoulders | forearm plank, straight rigid line head-to-heels; **core** | |
| `kneePlank` ✓DONE | hold | lying face-down, forearms under shoulders, knees down | knee plank on forearms+knees, straight line knees-to-head; **core** | |
| `sidePlank` ⏭existing | hold | lying on one side, forearm down, legs stacked | side forearm plank, hips lifted, body one line; **core** | |
| `vUp` ✓DONE | rep | lying flat on back, arms extended overhead | a folded V, arms and straight legs meeting over the hips; **core** | |
| `hollowHold` ✓DONE | hold | lying flat on back, arms by sides | shallow hollow, shoulders + straight legs lifted, low back down; **core** | grid final |
| `toesToBar` ⚡ | rep | dead hang from a bar, body long | toes swung up to touch the bar, body piked; **core, back** | full-motion |
| `lSit` ✓DONE | hold | seated, hands planted on floor, knees bent | legs extended straight forward, hips lifted, an L shape; **core, arms** | float fix = add "hands stay planted, supported on arms" |

## B6. Handstand progression  (CAM: side-profile, floor level; inverted moves head-down)

| clipId | type | START (left) | PEAK (right) + green | notes |
|---|---|---|---|---|
| `pikePushUp` | rep | pike position, hands and feet on floor, hips high, arms straight | head lowered toward the floor between the hands, elbows bent; **shoulders, arms** | |
| `wallHandstandHold` | hold | crouched, hands on floor near a wall, feet down | inverted handstand against the wall, body straight, arms locked; **shoulders, core** | one-way kick-up |
| `handstandPushUp` | rep | inverted handstand against a wall, arms locked | head lowered to the floor, elbows bent, still inverted; **shoulders, arms, core** | |

## B7. Jump / power  (CAM: side-profile, standing height — ⚡ full-motion)

| clipId | type | START (left) | PEAK (right) + green | notes |
|---|---|---|---|---|
| `burpee` ✓DONE | rep | standing | ⚡ full burpee cycle, jump with arms overhead; **fullBody** | |
| `halfBurpee` ⚡ | rep | standing | chest-to-floor then feet stepped back in, stand; no jump; **fullBody** | |
| `burpeeBoxJumpOver` ⚡ | rep | standing beside a box | burpee then a two-foot jump over the box; **fullBody** | long; longer duration |
| `stepUp` | rep | standing facing a box, one foot on the box | driven up to standing tall on top of the box; **quads, glutes** | |
| `boxJump` ⚡ | rep | standing facing a box | landed softly on top of the box in a quarter squat; **quads, glutes** | full-motion |
| `broadJump` ⚡ | rep | standing, arms back in a loaded hinge | mid-air horizontal leap, arms driving forward; **quads, glutes** | full-motion |

---

## C. Endurance / conditioning  (CAM per move — ⚡ most full-motion)

| clipId | type | CAM | START (left) | PEAK (right) + green | notes |
|---|---|---|---|---|---|
| `jumpingJack` ⚡ | rep | front-on | standing, arms at sides, feet together | feet wide, arms overhead (star); **fullBody, cardio** | ✓ exists in lib |
| `highKnees` ⚡ | rep | side-profile | standing tall | one knee driven to hip height, opposite arm up, on the ball of the foot; **quads, cardio** | |
| `mountainClimber` ✓DONE | rep | side-profile, floor | top plank, arms straight | one knee driven to the chest, other leg long; **core, cardio** | |
| `jumpRope` ⚡ | rep | front-on | standing, knees soft, hands at hips | mid small hop, wrists turning a rope; **calves, cardio** | |
| `doubleUnder` ⚡ | rep | front-on | standing, knees soft | higher hop, rope passing twice; **calves, cardio** | full-motion |
| `sledPush` | rep | side-profile | low athletic stance, arms extended onto a sled | driving forward, one leg extended behind, leaning into the sled; **fullBody, cardio** | |
| `sledPull` | rep | side-profile | standing, a rope taut in both hands | hauling backward, rope pulled to the hips; **back, cardio** | |
| `rowErg` | rep | side-profile | seated on an erg, arms extended, knees bent (catch) | legs straight, handle pulled to the ribs, slight lean back (finish); **back, quads, cardio** | |
| `airBike` | rep | side-profile | seated on an air bike, hands on the moving handles | mid-stride pedal + push/pull of the handles; **fullBody, cardio** | |
| `battleRopes` | rep | front-on | athletic stance, a rope end in each hand, arms low | mid-wave, one arm up one arm down, ropes cracking; **shoulders, arms, cardio** | |
| `sprintInPlace` ⚡ | rep | side-profile | athletic stance | mid-stride sprint, one knee high, opposite arm driving; **quads, cardio** | |

---

## D. Mobility  (CAM per pose; nearly all HOLD, one-way into the stretch)

| clipId | type | CAM | START (left) | PEAK (right) + green | 
|---|---|---|---|---|
| `ninetyNinetyHipStretch` | hold | 3/4 top | seated upright, both knees bent 90° (front + back leg) | torso folded over the front shin; **hip** |
| `assistedCossackSquat` | hold | front-on | wide stance, hands on a support | weight shifted over one bent leg, other leg straight, deep side lunge; **hip, quads** |
| `cossackSquat` | rep | front-on | wide stance, arms forward | deep shift onto one bent leg, other straight, heel down; **hip, quads** |
| `threadTheNeedle` | hold | 3/4 | quadruped on hands and knees | one arm threaded under the body, shoulder + temple to the floor; **shoulders, back** |
| `cobraStretch` | hold | side-profile, floor | lying face-down, hands under the shoulders | chest lifted, arms straightening, hips down, gentle back arch; **core, back** |
| `pigeonPose` | hold | 3/4 | quadruped | one shin folded forward on the floor, back leg extended, torso tall; **hip** |
| `quadStretch` | hold | side-profile | standing tall | standing on one leg, the other foot pulled to the glute by the hand; **quads** |
| `wristMobility` | hold | 3/4 | kneeling, hands flat on the floor | rocking the weight over the wrists, fingers pointing back; **wrist** |
| `scapularWallSlide` | rep | front-on | standing against a wall, arms bent 90° ("goalpost") | arms slid overhead to near-straight, staying on the wall; **shoulders, back** |
| `deepSquatHold` ✓DONE | hold | side-profile | standing | bottom of a deep squat, feet flat, torso tall, elbows inside knees; **hip, ankle** |
| `spinalTwist` | hold | top / 3/4 | seated, legs extended | torso rotated, one hand behind, opposite elbow across the knee; **back** |
| `ankleDorsiflexionStretch` | hold | side-profile | half-kneeling, front foot flat | front knee driven forward past the toes, heel down; **ankle** |

---

## Run order (écorché core)

1. **Finish existing-library progressions** (unlock levels now): `gobletSquat backSquat overheadSquat`,
   `benchPress pushPress`, `chestToBarPullUp`, `walkingLunge`, `kneePlank vUp lSit`.
2. **Foundational** hinge/press/pull/lunge intermediates: `hipHinge kettlebellDeadlift pendlayRow
   barbellRow ringRow benchDip barDip pikePushUp stepUp`.
3. **Conditioning** (fast, cheap): `highKnees jumpRope sprintInPlace rowErg airBike battleRopes
   sledPush sledPull`.
4. **Mobility** (high volume, all one-way holds): all of Section D.
5. **Advanced/skill** (retention): `pistolSquat archerPushUp ringDip muscleUp toesToBar
   handstandPushUp wallHandstandHold`.
6. **Ballistic ⚡** last (full-motion, no ping-pong, may need >4s): Olympic lifts, `kbSnatch
   turkishGetUp manMaker thruster jumpSquat boxJump broadJump doubleUnder halfBurpee
   burpeeBoxJumpOver kettlebellDeadliftSwing`.

Count: ~60 écorché core prompts (excludes the 8 already-DONE clips + `sidePlank`/`jumpingJack`
already wired). Each = 1 NB grid gen + 1 Seedance gen (+ retries).
