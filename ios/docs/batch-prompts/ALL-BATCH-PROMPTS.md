# All exercise prompts — master log (by batch)

Backup so any batch can be run by hand if we hit usage limits. Pipeline = `SEEDANCE-PROMPT-KIT.md` v4.

**Every clip = 2 steps:**
1. **NB grid** — `generate_image`, model `nano_banana_2`, `aspect_ratio 1:1`, `resolution 2k`. One
   1:1 two-panel image (LEFT = start, RIGHT = peak/hold). Split down the middle into two 9:16
   panels (scale each half to 720w, pad to 720×1280 white). Upload both to Higgsfield → media_ids.
2. **Seedance** — `generate_video`, model `seedance_2_0`, `start_image` = left panel, `end_image` =
   right panel, `aspect_ratio 9:16`, `duration 4`, `generate_audio false`, `resolution 720p`.
   If an "IN THE DARK" preset popup appears, choose generate-literally / decline preset.

Reference element embedded in every grid prompt: `<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>>` (écorché).
Rules: **lead with the exercise NAME** in both prompts · **never describe the figure's appearance /
render / anatomy — the reference drives that (HARD RULE 0); a grid prompt describes only name +
poses + camera + equipment + green highlight + framing** · side-profile for sagittal moves,
¾-front for bar pulls · "NO text/labels" on grids · one consistent piece of equipment across both
panels · for big vertical-translation moves (pull-ups) lock scale and let the body rise (feet lift).
Some earlier batch-1/2 grid prompts below predate the "lead with the name" rule — they still work,
but new prompts should follow it.

Manifest `type`: **rep** = app ping-pongs the A→B clip · **hold** = app plays in, counts down, reverses out.

---

# BATCH 1 ✓ done

## hollowHold  (hold · core · side-profile floor)
GRID:
```
<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> A clean two-panel side-by-side reference on a plain white background. ONE consistent figure in BOTH panels at the EXACT same scale, same side-profile camera at floor level, same ground line. Thin vertical gap splits it into LEFT and RIGHT. LEFT: the figure lies flat on its back on the floor, legs straight, arms by the sides. RIGHT: the SAME figure in a shallow hollow-body hold — lower back and hips pressed to the floor, only shoulders and straight legs lifted a few inches, arms reaching past the head; the core glows bright green. Whole body head-to-toe in frame in each panel, never cropped.
```
SEEDANCE:
```
Hollow-body hold demonstrated with correct form. 0:00–0:02 it rises from lying flat into a shallow hollow — shoulders and straight legs lifted a few inches off the floor, lower back staying down; 0:02–0:04 it holds, perfectly still. Locked static camera, plain white background. No music, no sound, no audio.
```

## vUp  (rep · core · side-profile floor)
GRID:
```
<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> A clean two-panel side-by-side reference on a plain white background. ONE consistent figure in BOTH panels at the EXACT same scale, same side-profile camera at floor level, same ground line. Thin vertical gap into LEFT and RIGHT. LEFT: the figure lies flat on its back, arms extended straight overhead on the floor. RIGHT: the SAME figure at the top of a V-up — folded into a shallow V balanced on the glutes, straight arms and straight legs lifted to meet over the hips; the core glows bright green. Whole body in frame in each panel, never cropped.
```
SEEDANCE:
```
V-up demonstrated with correct form. 0:00–0:03 it folds smoothly from lying flat into a V, straight arms and straight legs lifting to meet over the hips, balanced on the glutes; 0:03–0:04 it holds the top. Locked static camera, plain white background. No music, no sound, no audio.
```

## kneePlank  (hold · core · side-profile floor)
GRID:
```
<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> A clean two-panel side-by-side reference on a plain white background. ONE consistent figure in BOTH panels at the EXACT same scale, same side-profile camera at floor level, same ground line. Thin vertical gap into LEFT and RIGHT. LEFT: the figure lies face-down, forearms flat under the shoulders, knees down. RIGHT: the SAME figure holds a knee plank — up on the forearms and knees, a straight rigid line from knees to head, hips level; the core glows bright green. Whole body in frame in each panel, never cropped.
```
SEEDANCE:
```
Knee plank demonstrated with correct form. 0:00–0:02 it rises from lying face-down up onto its forearms and knees into a straight rigid line from the knees to the head, hips level; 0:02–0:04 it holds, perfectly still. Locked static camera, plain white background. No music, no sound, no audio.
```

## gobletSquat  (rep · quads, glutes · side-profile standing)
GRID:
```
<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> A clean two-panel side-by-side reference on a plain white background. ONE consistent figure in BOTH panels at the EXACT same scale, same side-profile camera at standing height, same ground line. Thin vertical gap into LEFT and RIGHT. LEFT: the figure stands tall, both hands cupping a kettlebell at the chest. RIGHT: the SAME figure at the bottom of a goblet squat — hips below the knees, elbows inside the knees, torso tall, kettlebell at the chest; the quads and glutes glow bright green. Whole body head-to-toe in frame, never cropped.
```
SEEDANCE:
```
Goblet squat demonstrated with correct form. 0:00–0:03 it descends smoothly from standing to the bottom of the squat, hips below the knees, torso tall, kettlebell held at the chest; 0:03–0:04 it holds the bottom. Locked static camera, plain white background. No music, no sound, no audio.
```

## walkingLunge  (rep · quads, glutes · side-profile standing)
GRID:
```
<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> A clean two-panel side-by-side reference on a plain white background. ONE consistent figure in BOTH panels at the EXACT same scale, same side-profile camera at standing height, same ground line. Thin vertical gap into LEFT and RIGHT. LEFT: the figure stands tall, feet together, arms relaxed. RIGHT: the SAME figure in the bottom of a forward lunge — one foot forward, both knees bent ~90 degrees, front shin vertical, torso upright; the quads and glutes glow bright green. Whole body head-to-toe in frame, never cropped.
```
SEEDANCE:
```
Forward lunge demonstrated with correct form. 0:00–0:03 it steps one foot forward and lowers into a lunge, both knees about ninety degrees, front shin vertical, torso upright; 0:03–0:04 it holds the lunge. Locked static camera, plain white background. No music, no sound, no audio.
```

## squat (crop-fix replacement)  (rep · quads, glutes · side-profile standing)
GRID:
```
<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> A clean two-panel side-by-side reference on a plain white background. ONE consistent figure in BOTH panels at the EXACT same scale, same side-profile camera at standing height, same ground line, with clear empty margin above the head and below the feet. Thin vertical gap into LEFT and RIGHT. LEFT: the figure stands tall, feet hip-width, arms relaxed. RIGHT: the SAME figure at the bottom of a bodyweight air squat — hips below the knees, arms extended straight forward for balance, torso tall and chest up; the quads and glutes glow bright green. Whole body from the top of the head to the feet in frame, never cropped, clear space above head and below feet.
```
SEEDANCE:
```
Bodyweight squat performed with correct form. 0:00–0:03 the figure descends smoothly from standing to the bottom of the squat — hips below the knees, arms reaching forward, torso tall and chest up; 0:03–0:04 it holds the bottom. Locked static camera, plain white background. No music, no sound, no audio.
```

---

# BATCH 2 ✓ done

(full prompts also in `batch-02.md`.) lSit here is the final core+quads version.

## lSit  (hold · core + quads · side-profile floor)
GRID:
```
<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> A clean two-panel side-by-side reference on a plain white background. ONE consistent figure in BOTH panels at the EXACT same scale, same side-profile camera at floor level, same ground line. Thin vertical gap into LEFT and RIGHT. LEFT: the figure sits on the floor, both hands planted flat beside the hips, knees bent, feet flat. RIGHT: the SAME figure holds an L-sit — both arms locked straight pressing into the floor, shoulders pushed down, hips lifted off the floor, both legs extended straight forward into an L; the core, hip flexors AND the quadriceps of both legs glow bright green. Whole body in frame, never cropped.
```
SEEDANCE:
```
L-sit demonstrated with correct form. 0:00–0:02 the figure presses down through both hands planted flat on the floor and lifts the hips, extending both legs straight forward into an L; 0:02–0:04 it holds, perfectly still, hands staying on the floor and the body supported on straight arms, never floating. Static locked camera, plain white background. No music, no sound, no audio.
```

## backSquat  (rep · quads, glutes · side-profile standing)
GRID:
```
<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> A clean two-panel side-by-side reference on a plain white background. ONE consistent figure in BOTH panels at the EXACT same scale, same side-profile camera at standing height, same ground line, clear margin above head and below feet. Thin vertical gap into LEFT and RIGHT. LEFT: the figure stands tall, a long barbell racked across the upper back/traps, both hands gripping the bar. RIGHT: the SAME figure at the bottom of a back squat — hips below the knees, bar still on the upper back, bar over the midfoot, torso braced; the quads and glutes glow bright green. Whole body head-to-toe in frame, never cropped.
```
SEEDANCE:
```
Barbell back squat performed with correct form. 0:00–0:03 the figure descends smoothly from standing to below parallel, keeping the bar over the midfoot and the torso braced; 0:03–0:04 it holds the bottom. Locked static camera, plain white background. No music, no sound, no audio.
```

## overheadSquat  (rep · quads, glutes, shoulders · side-profile standing)
GRID:
```
<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> A clean two-panel side-by-side reference on a plain white background. ONE consistent figure in BOTH panels at the EXACT same scale, same side-profile camera at standing height, same ground line, clear margin above head and below feet. Thin vertical gap into LEFT and RIGHT. LEFT: the figure stands tall, a long barbell locked overhead with straight arms in a wide grip, over the midfoot. RIGHT: the SAME figure at full depth of an overhead squat — hips well below the knees, barbell still locked overhead over the midfoot, torso upright; the quads, glutes and shoulders glow bright green. Whole body head-to-toe in frame, never cropped.
```
SEEDANCE:
```
Barbell overhead squat performed with correct form. 0:00–0:03 the figure descends to full depth keeping the barbell locked overhead over the midfoot, arms straight; 0:03–0:04 it holds the bottom. Locked static camera, plain white background. No music, no sound, no audio.
```

## benchPress  (rep · chest, shoulders, arms · side-profile, bench height)
GRID:
```
<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> A clean two-panel side-by-side reference on a plain white background. NO text or labels. ONE consistent figure in BOTH panels at the EXACT same scale, same side-profile camera at bench height, same ground line. Thin vertical gap into LEFT and RIGHT. Both panels: the figure lies on its back on a flat bench, feet on the floor. LEFT: a long barbell held at the chest, elbows ~45 degrees. RIGHT: the SAME figure with the barbell pressed to a straight-arm lockout over the chest; the chest, shoulders and triceps glow bright green. Whole body in frame, never cropped.
```
SEEDANCE:
```
Barbell bench press performed with correct form. 0:00–0:03 from the bar at the chest the figure presses the barbell straight up to a full lockout over the chest; 0:03–0:04 it holds the lockout. Locked static camera, plain white background. No music, no sound, no audio.
```

## pushPress  (rep · shoulders, arms, quads · side-profile standing)
GRID:
```
<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> A clean two-panel side-by-side reference on a plain white background. NO text, labels, captions or annotations — only the figure. ONE consistent figure in BOTH panels at the EXACT same scale, same side-profile camera at standing height, same ground line, clear margin above head and below feet. Thin vertical gap into LEFT and RIGHT. LEFT: the figure stands with a barbell racked at the front of the shoulders, in a slight knee dip. RIGHT: the SAME figure with the barbell driven to a locked-out overhead position, arms straight, ribs down, legs extended; the shoulders, triceps and quads glow bright green. Whole body head-to-toe in frame, never cropped.
```
SEEDANCE:
```
Barbell push press performed with correct form. 0:00–0:02 from a shoulder rack with a quick knee dip the figure drives the barbell to a locked-out overhead position; 0:02–0:04 it holds the lockout. Locked static camera, plain white background. No music, no sound, no audio.
```

## chestToBar  (rep · back, arms · ¾-front, scale-locked)
GRID:
```
<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> A clean two-panel side-by-side reference on a plain white background. NO text or labels. ONE figure from a THREE-QUARTER FRONT camera so both arms and both hands are visible. CRITICAL: the figure is the IDENTICAL size in BOTH panels — do NOT zoom or rescale. Exactly ONE straight horizontal pull-up bar fixed at the same height near the top of both panels; both hands grip it OVERHAND (pronated), slightly wider than shoulders. Thin vertical gap into LEFT and RIGHT. LEFT: a full dead hang, arms straight, body long, feet low. RIGHT: the SAME figure has pulled its whole body straight UP so the upper chest meets the bar, elbows bent down and back; the body sits HIGHER in the frame with the feet lifted off the ground and empty space below. Same figure scale in both — only vertical position and arm bend change. Lats and biceps glow bright green in the right panel. Head and hands never cropped at top.
```
SEEDANCE:
```
Chest-to-bar pull-up performed with correct form. 0:00–0:02 from a dead hang the figure pulls its whole body straight up until the chest meets the bar, elbows driving down and back; 0:02–0:04 it holds the top. The bar stays fixed. Locked static camera, plain white background. No music, no sound, no audio.
```

---

# BATCH 3 — foundational intermediates (running)

## hipHinge  (rep · hamstrings, glutes · side-profile standing)
GRID:
```
<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> A clean two-panel side-by-side reference on a plain white background. NO text or labels. ONE consistent figure in BOTH panels at the EXACT same scale, same side-profile camera at standing height, same ground line, clear margin above head and below feet. Thin vertical gap into LEFT and RIGHT. LEFT: the figure stands tall, hands on the hips. RIGHT: the SAME figure demonstrating a hip hinge — hips pushed back, flat back tipped to near parallel with the floor, knees softly bent, hands still on the hips; the hamstrings and glutes glow bright green. Whole body head-to-toe in frame, never cropped.
```
SEEDANCE:
```
Hip hinge demonstrated with correct form. 0:00–0:03 from standing tall the figure pushes the hips back into a hinge, flat back tipping to near parallel, knees soft; 0:03–0:04 it holds. Locked static camera, plain white background. No music, no sound, no audio.
```

## kettlebellDeadlift  (rep · hamstrings, glutes, back · side-profile standing)
GRID:
```
<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> A clean two-panel side-by-side reference on a plain white background. NO text or labels. ONE consistent figure in BOTH panels at the EXACT same scale, same side-profile camera at standing height, same ground line, clear margin above head and below feet. Thin vertical gap into LEFT and RIGHT. LEFT: the figure is hinged over a single kettlebell resting on the floor between the feet, flat back, both hands gripping the handle. RIGHT: the SAME figure stands tall at full lockout holding the same kettlebell at arm's length in front of the hips, hips fully extended; the hamstrings, glutes and back glow bright green. Whole body head-to-toe in frame, never cropped.
```
SEEDANCE:
```
Kettlebell deadlift performed with correct form. 0:00–0:03 from a flat-back setup gripping the kettlebell on the floor the figure drives the hips forward and stands to a tall lockout holding the kettlebell; 0:03–0:04 it holds the lockout. Locked static camera, plain white background. No music, no sound, no audio.
```

## pendlayRow  (rep · back, arms · side-profile)
GRID:
```
<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> A clean two-panel side-by-side reference on a plain white background. NO text or labels. ONE consistent figure in BOTH panels at the EXACT same scale, same side-profile camera at standing height, same ground line. Thin vertical gap into LEFT and RIGHT. LEFT: the figure is hinged over to near parallel, back flat, a long barbell resting on the floor with the arms hanging straight down gripping it. RIGHT: the SAME figure has pulled the barbell up to the lower ribs, elbows high, back still flat and parallel; the back (lats) and biceps glow bright green. Whole body in frame, never cropped.
```
SEEDANCE:
```
Pendlay row performed with correct form. 0:00–0:02 from a flat back over the barbell on the floor the figure pulls the bar to the lower ribs, elbows high, back parallel; 0:02–0:04 it holds. Locked static camera, plain white background. No music, no sound, no audio.
```

## barbellRow  (rep · back, arms · side-profile)
GRID:
```
<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> A clean two-panel side-by-side reference on a plain white background. NO text or labels. ONE consistent figure in BOTH panels at the EXACT same scale, same side-profile camera at standing height, same ground line. Thin vertical gap into LEFT and RIGHT. LEFT: the figure is hinged over about 45 degrees, back flat, a long barbell hanging at the thighs with straight arms. RIGHT: the SAME figure has pulled the barbell to the waist, elbows driven past the ribs, torso angle unchanged; the back (lats) and biceps glow bright green. Whole body in frame, never cropped.
```
SEEDANCE:
```
Barbell bent-over row performed with correct form. 0:00–0:02 from a hinged flat-back position the figure pulls the barbell to the waist, elbows past the ribs; 0:02–0:04 it holds. Locked static camera, plain white background. No music, no sound, no audio.
```

## bandRow  (rep · back, arms · side-profile floor)  ← replaces ringRow (rings = expansion set)
GRID:
```
<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> SEATED RESISTANCE-BAND ROW — two-panel side-by-side reference, plain white background, no text or labels. Same figure at the same scale in both panels, side-profile camera at floor level, same ground line. The figure sits on the floor with the legs extended straight forward and a resistance band looped around the soles of both feet, holding one end of the band in each hand. LEFT: arms extended straight forward toward the feet, torso upright — the stretched start. RIGHT: the figure has pulled both band ends back to the lower ribs, elbows driven straight back past the torso, chest tall; the back and biceps glow bright green. Whole body head-to-toe in frame in each panel, never cropped.
```
SEEDANCE:
```
Seated resistance-band row performed with correct form. 0:00–0:02 from arms extended forward the figure pulls both band ends back to the lower ribs, elbows driving straight back, chest tall; 0:02–0:04 it holds. Locked static camera, plain white background. No music, no sound, no audio.
```

## bandRowSeated  (rep · back, arms · side-profile · accessibility variant, seated on a block/chair)
SEEDANCE:
```
Seated resistance-band row, seated on a block — performed with correct form. 0:00–0:02 from arms extended forward the figure pulls both band ends back to the lower ribs, elbows driving straight back, chest tall; 0:02–0:04 it holds. Locked static camera, plain white background. No music, no sound, no audio.
```
(Same movement as bandRow, seated on a block/chair — for users who can't get to the floor. Not a difficulty tier.)

> **Gymnastics expansion set (deferred, not core):** rings/gymnastics-only movements the average
> at-home user can't do — `ringRow`, `ringDip`, `muscleUp`. Generated later as a separate pack,
> not part of the accessible core catalog. (Also deferred: `hipHinge` — NB's content filter
> repeatedly rejects the écorché hinge pose; revisit or author in the Higgsfield UI.)

## benchDip  (rep · triceps, chest · side-profile)
GRID:
```
<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> A clean two-panel side-by-side reference on a plain white background. NO text or labels. ONE consistent figure in BOTH panels at the EXACT same scale, same side-profile camera, same ground line. The SAME single flat bench in both panels. Thin vertical gap into LEFT and RIGHT. LEFT: the figure supports itself with both hands on the edge of the bench behind it, hips off the bench, arms straight, legs extended forward with heels on the floor. RIGHT: the SAME figure has lowered the hips, elbows bent about 90 degrees pointing back; the triceps and chest glow bright green. Whole body in frame, never cropped.
```
SEEDANCE:
```
Bench dip performed with correct form. 0:00–0:02 from a straight-arm support on the bench the figure lowers the hips until the elbows bend to about ninety degrees pointing back; 0:02–0:04 it holds the bottom. Locked static camera, plain white background. No music, no sound, no audio.
```

