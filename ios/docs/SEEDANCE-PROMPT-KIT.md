# Seedance exercise-clip prompt kit

Built on the user's proven Subject / Action / Camera / Style / Constraints structure.
One clip = **one exercise, one rep, 4s seamless loop, 9:16, 720p, NO audio.** Only the
**Action** field changes per exercise; everything else stays word-for-word identical.

Character reference element: **@[écorché](e18e4b6e-e85f-4639-bdc0-221abaf778c8)**

**Two hard rules (QC):**
1. Every prompt embeds an **expert form description to CrossFit / functional-fitness movement
   standards** — so form and muscle recruitment are correct every time. A staff trainer signs
   off each clip.
2. **No music, no sound, no audio.** In the MCP call set `generate_audio: false` AND state it
   in Constraints (belt and suspenders).

Loop rule: the rep starts and ends in the same neutral pose → seamless 4s loop (verified on
the squat: first vs last frame <3%).

---

## MASTER TEMPLATE (edit only the {CAPS} parts in Action)

**Subject:** Animate @[écorché](e18e4b6e-e85f-4639-bdc0-221abaf778c8) to maintain identical
body proportions and facial features.

**Action:** Seamless, continuous 4-second loop, no audio. The character performs one full,
**single, deliberately slow and controlled rep** of {EXERCISE} — **exactly one repetition, not
multiple** — at a natural demonstration tempo (soft anchor: roughly ~2s on the lowering /
eccentric and ~2s on the lift / concentric) so the one rep smoothly fills the clip and returns
to the start. This is the median between true rep tempo and a clean loop: guide the tempo, do
not force-fill, but keep it to ONE rep. {EXPERT FORM DESCRIPTION — CrossFit / functional-fitness
movement standard: setup, positions the rep must hit, common faults to avoid}. Move with
realistic weight transfer; begin and end in {NEUTRAL POSE} so it loops with no jump. During the
exertion (concentric) phase the prime-mover muscles — {TARGET MUSCLES} — glow neon green,
fading back to the blue-violet musculature at the return. One rep only.

**Camera:** Static shot, centered and locked on the character's midsection, no panning or
zooming, full body framed head-to-feet with margin so nothing is cropped.

**Style & Environment:** Plain neutral white background, studio lighting, clean soft contact
shadow grounding the figure, crisp definition; translucent glossy blue-violet x-ray
musculature with visible striations, pale tendons, and a soft cyan edge glow.

**Constraints:** Maintain strict character consistency throughout the loop. No background
changes, no flickering, no identity drift, no extra objects, no text, no camera movement,
one rep only, **no audio, no music, no sound.**

MCP call params: `model: seedance_2_0, aspect_ratio: 9:16, duration: 4, generate_audio: false`.

---

## Expert form descriptions (CrossFit / functional-fitness standards)

- **Air squat:** feet shoulder-width, toes slightly out; initiate at the hips, sit back and
  down; hip crease clearly **below the top of the knee (below parallel)**; knees track over
  toes, heels stay planted, lumbar neutral, chest up; stand to **full hip and knee extension**.
  Faults to avoid: heels lifting, knees caving, rounding the back, cutting depth. Prime movers:
  **quadriceps, glutes** (hamstrings assist).
- **Push-up:** start at full elbow lockout, body a **rigid straight line heel-to-head** (hollow
  plank, glutes + core braced); lower under control until **chest touches the floor**, elbows
  tracking ~45° to the ribcage (not flared wide); press to **full lockout** keeping the line.
  Faults: hips sagging or piking, partial depth, flared elbows. Prime movers: **pectorals,
  triceps** (anterior deltoids assist).
- **Forward lunge:** step forward, lower until **both knees ~90°**, front shin vertical, front
  heel down, torso tall; rear knee gently toward floor; drive through the front heel back to
  standing. Prime movers: **quadriceps, glutes** (hamstrings assist).

Add more here as the library grows; keep the same "setup → positions → faults → prime movers"
shape.

---

## TEST #2 — PUSH-UP (current, with expert form + no audio)

**Subject:** Animate @[écorché](e18e4b6e-e85f-4639-bdc0-221abaf778c8) to maintain identical
body proportions and facial features.

**Action:** Seamless, continuous 4-second loop, no audio. The character performs one full,
controlled push-up to CrossFit standard: begin at the top with arms fully locked out and the
body in a rigid straight line from heels to head (hollow plank, glutes and core braced, hips
neither sagging nor piking); lower under control until the chest touches the floor with the
elbows tracking about 45 degrees to the ribcage (not flared wide); then press evenly back to
full elbow lockout, holding the straight rigid line throughout. Move with realistic weight
transfer; begin and end in the top plank position so it loops with no jump. During the
press-up (concentric) phase the prime-mover muscles — chest (pectorals) and triceps — glow
neon green, fading back to the blue-violet musculature at the top. One rep only.

**Camera:** Static shot, centered and locked on the character's midsection, no panning or
zooming, full body framed head-to-feet with margin so nothing is cropped.

**Style & Environment:** Plain neutral white background, studio lighting, clean soft contact
shadow grounding the figure, crisp definition; translucent glossy blue-violet x-ray
musculature with visible striations, pale tendons, and a soft cyan edge glow.

**Constraints:** Maintain strict character consistency throughout the loop. No background
changes, no flickering, no identity drift, no extra objects, no text, no camera movement,
one rep only, no audio, no music, no sound.

---

## Check every generation (log retries per clip)

1. **Character match** — identical to the squat clip.
2. **Form** — trainer-verified to CrossFit standard.
3. **Highlight** — correct prime movers, neon green, during the exertion phase only.
4. **Loop** — same neutral pose start/end (first vs last frame near-identical).
