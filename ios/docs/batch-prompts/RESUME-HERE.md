# Resume point (écorché exercise clips)

## Where we are
- Pipeline: `SEEDANCE-PROMPT-KIT.md` v4. All prompts: `ALL-BATCH-PROMPTS.md`.
- Library: `ios/Metabolic/ExerciseClips/` + `exercise-clips.json` — **24 clips** (batches 1 & 2 done).
- **Batch 3 in progress** — grids done, 12 panels split and waiting to upload.

## Batch 3 — pending upload → Seedance → encode
Panels ready at `ios/Auxilliaery/archive/_dev/panels/batch3/` (start+end each):
`bandRow` (seated floor band row), `bandRowSeated` (block/chair accessibility variant),
`barbellRow`, `benchDip`, `kettlebellDeadlift`, `pendlayRow`.

Next steps:
1. Upload the 12 panels to Higgsfield → media_ids (map by filename).
2. Run 6 Seedance interpolations — prompts in `ALL-BATCH-PROMPTS.md` § BATCH 3 (`seedance_2_0`,
   start_image=left, end_image=right, 9:16, duration 4, generate_audio false, 720p).
3. Download masters → encode HEVC (`ffmpeg -i SRC -vf scale=720:1280:flags=lanczos -an -c:v
   libx265 -crf 28 -tag:v hvc1 -preset fast -movflags +faststart {clipId}.mp4`).
4. Add entries to `exercise-clips.json` (bandRow/benchDip/kettlebellDeadlift=rep or as noted;
   all rows=rep; benchDip=rep). Archive masters to `archive/_dev/`.

## Deferred
- `hipHinge` — NB Pro NSFW filter repeatedly rejects the écorché hinge pose. Try the Higgsfield
  UI, or a clothed/alternate depiction.
- **Gymnastics expansion set** (not core, needs rings/gym): `ringRow`, `ringDip`, `muscleUp`.

## Hard-won rules (in the kit)
- Grid + Seedance prompts: **lead with the exercise NAME**; **never describe the écorché figure's
  appearance/render/anatomy** — the `<<<e18e4b6e-e85f-4639-bdc0-221abaf778c8>>>` reference drives it.
- Camera: side-profile for sagittal moves; ¾-front for bar pulls.
- Grids: "NO text/labels"; one consistent piece of equipment across both panels.
- Pull-ups: lock figure scale, let the body rise (feet lift) — don't force feet-to-bottom.
- Seedance: end_image is a soft target (name the exact variant); keep the timing/hold clause to
  stop overshoot; green can wash out (add "core stays green" if so); "neon/slow motion/dark" trip
  a preset popup → retry with `declined_preset_id`.

## Environment constraints (this agent)
- Sandbox CANNOT `git push` (read-only .git) or upload to Higgsfield → the user does both.
- Sandbox CANNOT download Higgsfield CDN → user saves generated files locally for QC.
- Upload path: user uploads panels in Higgsfield; paste media_ids (with filenames) back to chat.

## Push (from user's Mac, repo root)
```bash
rm -f .git/index.lock
git add ios/Metabolic/ExerciseClips/ ios/docs/
git commit -m "exercise clips + prompt docs"
git push origin claude/ios-fitness-tracking-app-qanedu
```
