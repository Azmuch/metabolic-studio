# Seedance exercise-clip prompt kit (v4 — GRID METHOD, validated)

**9:16, 720p, no audio, @[écorché](e18e4b6e-e85f-4639-bdc0-221abaf778c8) reference.**
Embed the reference as `<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>>`.

---

## ★ VALIDATED PIPELINE — grid keyframes → Seedance interpolation

Proven on `plank` and `hollowHold`. This is the primary method; use it for every clip.

**Step 1 — one 1:1 two-panel keyframe grid (Nano Banana Pro, `nano_banana_2`).**
Generate BOTH keyframes in a SINGLE image so they share identical scale, camera, render, and
ground line. This is the whole point — separate generations drift in scale and Seedance then
*morphs* the body size mid-move instead of moving a rigid figure.

> `<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>>` A clean two-panel side-by-side reference on a
> plain white background. ONE single consistent figure is shown in BOTH panels at the EXACT
> same body scale and proportions, same side-profile camera at floor level, same ground line and
> same distance from camera. A thin vertical gap splits the image down the exact center into a
> LEFT panel and a RIGHT panel. LEFT panel: {NEUTRAL / START pose}. RIGHT panel: the SAME figure
> {PEAK / HOLD pose}; {TARGET MUSCLES} glow bright green. Whole body head-to-toe fully in frame
> in each panel, never cropped, feet and head never touching the panel edges.

Params: `model:nano_banana_2, aspect_ratio:"1:1", resolution:"2k"`. (NB may return a 2×2 — top
row is start|end and is fine; just crop the top row.)

**Step 2 — split + upload.** Crop the grid into two 9:16 panels (scale each half to 720 wide,
pad to 720×1280 white, centered — identical treatment so both stay matched). The agent sandbox
cannot reach Higgsfield's CDN/upload host, so the USER uploads the two panels via the Higgsfield
`media_upload_widget` (or the UI); that returns two `media_id`s.

**Step 3 — Seedance interpolation, STRIPPED prompt.** `seedance_2_0`, panels as `start_image`
(left/neutral) + `end_image` (right/peak). Keep the prompt SHORT — a long prompt fights the
reference frames and causes overshoot (e.g. plank → pike) and highlight loss.

> The figure demonstrates one {EXERCISE NAME} with correct textbook {functional-fitness /
> CrossFit} form and technique. 0:00–0:02 it moves from {start} into the {end/peak}; 0:02–0:04
> it holds, perfectly still. Locked static camera, plain white background. No music, no sound,
> no audio.

(For a REP, replace the hold with "returns to the start"; the app ping-pongs the A→B clip.)
Params: `aspect_ratio:"9:16", duration:4, generate_audio:false, resolution:"720p"`.

### Grid authoring rules (learned across batches)
- **HARD RULE 0 applies to the GRID too — never describe the figure.** Do NOT write the figure's
  appearance, colour, render style ("translucent blue-violet", "not grey"), or anatomy ("two
  arms", "no extra limbs") in the grid prompt. The `<<<écorché>>>` reference drives ALL of that;
  re-describing it splits attention and *causes* the drift (grey renders, extra limbs). Describe
  ONLY: exercise name, the two poses, camera, equipment, green highlight, framing. If a defect
  like an extra limb appears, re-roll — don't try to prompt it away with anatomy description.
- **Name the exercise, and lead the grid prompt with it.** Start the grid prompt with the
  exercise name in caps ("RING ROW (inverted row) — two-panel reference…"), and name it in the
  Seedance prompt too. Both models render the right movement far more reliably when named.
- **Camera by movement plane.** Side-profile for sagittal moves (squat, hinge, press, lunge,
  plank, floor core) — shows depth. **¾-front** for bar pulls (pull-up, chest-to-bar, muscle-up,
  toes-to-bar) so BOTH hands + grip are visible; side profile hides the far arm and the grip.
- **Guard against baked text.** NB sometimes turns the anatomical style into an instructional
  diagram with labels. Add "NO text, labels, captions, annotations, arrows — only the figure."
- **Equipment consistency.** State "exactly ONE bar in the identical position in both panels,
  no extra/diagonal bars" — NB otherwise draws different rigs per panel.
- **Big vertical-translation moves (pull-ups).** "Full body in frame both panels" + "bar fixed
  at top" conflict → NB rescales the figure to compensate. Instead: lock scale explicitly ("the
  figure is the IDENTICAL size in both panels, do not zoom") and let the body RISE — feet lift
  off the ground with empty space below in the pulled-up panel. Don't force feet-to-bottom.

### Two hard-won Seedance lessons
1. **`end_image` is a SOFT target.** When Seedance's motion prior conflicts with the end pose,
   the prior wins (forearm plank → straight-arm plank). Name the *specific* variant in the
   stripped prompt ("forearm plank, on the elbows") — but do NOT pile on paragraphs; one clause.
2. **The green highlight can wash out** through interpolation (it only exists in the end frame).
   If the montage shows it faded, add one clause: "core stays glowing green through the hold."
3. **Higgsfield preset auto-match:** "neon", "slow motion", "dark", etc. trip a preset popup —
   retry with `declined_preset_id`, or just say "bright green" instead of "neon green".

---

## HARD RULES

0. **Prompt the ACTION, never the character.** The reference image already defines the figure —
   translucent blue-violet musculature, cyan glow, striations, proportions, holographic skin.
   **Do NOT re-describe any of that in the prompt.** Describing it makes Seedance reconcile two
   sources and drift/distort. The prompt says only: *what exercise, how it moves, and the
   composition/highlight that are NOT in the reference* (white bg, green highlight, framing,
   loop/hold, no music/crop). Keep prompts short.
1. **Name the exercise.** Seedance knows exercise names — lead with the name, add a few form cues.
2. **Professional trainer, textbook form.** State the figure is a professional trainer
   demonstrating correct {functional-fitness / CrossFit / military} technique.
3. **Hard no-crop, wide shot.** "Whole body head-to-toe stays fully in frame, never cropped."
4. **Reps loop, holds don't.** REP = one rep, neutral→rep→neutral, seamless loop. HOLD =
   one-way, neutral→into the hold, ends held (app counts down + plays reversed to exit).
5. **Floor moves stay grounded.** Say which parts stay on the floor; body never floats/tilts up.
6. **No music, no sound, no audio.** Always `generate_audio:false` + state it.

---

## MASTER — REP (minimal; edit the {CAPS})

> <<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> — keep the character's exact proportions and
> appearance. As a professional trainer, perform one textbook **{EXERCISE NAME}** with correct
> {functional-fitness / CrossFit} form: {ONE short line of key form cues}. Exactly one controlled
> rep at natural tempo; begin and end in {NEUTRAL POSE} so it loops seamlessly. {TARGET MUSCLES}
> glow neon green on the exertion. Static wide shot, plain white background, whole body head-to-toe
> fully in frame and never cropped. No music, no sound, no audio.

## MASTER — HOLD (minimal; one-way, NOT a loop)

> <<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>> — keep the character's exact proportions and
> appearance. As a professional trainer, move from {NEUTRAL POSE} into a textbook **{HOLD NAME}**
> and settle, ending in the hold — one-way, not a loop. {GROUNDING CUE if on the floor}.
> {TARGET MUSCLES} glow neon green in the hold. Static wide shot, plain white background, whole
> body head-to-toe fully in frame and never cropped. No music, no sound, no audio.

Params every call: `model:seedance_2_0, aspect_ratio:9:16, duration:4, generate_audio:false`.

---

## Form cues (one line each; grows as authored)

- **air squat** — hips back, below parallel, knees over toes, stand tall. quads, glutes.
- **push-up** — rigid line, chest to floor, elbows ~45°, full lockout. chest, triceps.
- **reverse / forward lunge** — both knees ~90°, front shin vertical, drive up. quads, glutes.
- **bulgarian split squat** — rear foot on bench, front thigh to parallel, drive up. quads, glutes.
- **box squat** — sit back to touch a low box, stand. quads, glutes.
- **front squat** — bar racked on FRONT delts, elbows high, below parallel, stand. quads, glutes, core.
- **knee push-up** — knees down, chest to floor, press up. chest, triceps.
- **pull-up** — dead hang, chin over bar, lower to full hang. back, biceps.
- **burpee** — floor, plank, chest down, jump up arms overhead. full body.
- **mountain climber** (rep) — high plank, alternate knees to chest in a run rhythm. core.
- **hollow hold** (hold, floor) — low back + hips PRESSED to floor; only shoulders + legs lift a
  few inches; body stays grounded, never floats. core.
- **deep squat hold** (hold) — sink to bottom of squat, feet flat, torso tall. hips, adductors, ankles.

---

## ESCALATION — Nano Banana Pro first/last frame (for poses text-to-video keeps getting wrong)

Olympic lifts, muscle-ups, pistol squats, unusual holds, anything that fails 2× on the simple
prompt: control the exact poses with keyframes.

1. **Start frame** — `generate_image` model `nano_banana_2` (Nano Banana Pro), reference
   `<<<écorché>>>`, prompt only the exact START pose (e.g. "standing tall, arms at sides").
2. **End frame** — same, prompt the exact END / hold pose.
3. **Seedance image-to-video** — `generate_video` model `seedance_2_0`, pass the two images via
   `medias` roles **start_image** and **end_image**, prompt only the transition. For a REP loop
   use the same image as start and end; for a HOLD, start=neutral, end=hold pose.

Cost ≈ 3 generations/clip — reserve for the hard cases; use plain text-to-video for the bulk.

---

## Acceptance (per clip; trainer signs form)

1. Correct, recognizable exercise. 2. Character consistent, anatomy right, not floating.
3. No crop — full body in frame. 4. Correct muscles neon green. 5. Reps: first≈last frame;
Holds: end cleanly in the position.
