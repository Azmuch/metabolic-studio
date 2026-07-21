#!/bin/bash
# Downloads the Higgsfield-generated anatomy illustrations into the asset catalog.
# Run ONCE from the repo root on a machine with open network (your Mac):
#
#   bash ios/tools/fetch_anatomy_assets.sh
#
# then commit the new files under ios/Metabolic/Assets.xcassets/Anatomy/.
# The app falls back to the vector skeleton animation for any missing asset,
# so this step is safe to defer — it just unlocks the realistic anatomy heroes.

set -euo pipefail
cd "$(dirname "$0")/../Metabolic/Assets.xcassets"

BASE="https://d8j0ntlcm91z4.cloudfront.net/user_334XYdkoIBhH7wL9M1hEb87zLUO"

declare -a ASSETS=(
  "anatomy.squat.a|hf_20260711_143208_bd577951-6b89-4a05-b891-a9644b6e2fa0.png"
  "anatomy.squat.b|hf_20260711_142946_8b24305a-1b72-4dfc-ac8b-c7453110ba82.png"
  "anatomy.pushUp.a|hf_20260711_143210_1f33a0e1-aad1-4c85-bdc0-70f1439d97a0.png"
  "anatomy.pushUp.b|hf_20260711_143213_9f7f31b6-4da2-4559-8058-349c7fca03f5.png"
  "anatomy.lunge.a|hf_20260711_143226_84b7f52d-69f1-4cab-a223-7b5225a4f7bf.png"
  "anatomy.lunge.b|hf_20260711_143215_2da2d35f-8336-4f46-b359-4b3f5c11e1b1.png"
  "anatomy.pullUp.a|hf_20260711_143228_0d98f1b9-c531-45bc-aed9-4c848a81a394.png"
  "anatomy.pullUp.b|hf_20260711_143230_fb35bd08-3837-44fc-82a9-e6d920e015d3.png"
  "anatomy.kbSwing.a|hf_20260711_143233_9a03893d-9f47-4cfa-8031-2fc04848966b.png"
  "anatomy.kbSwing.b|hf_20260711_143244_f60b5850-4e49-4867-ab21-623d85c4d643.png"
  "anatomy.gluteBridge.a|hf_20260711_143249_ed548b5d-c6ce-430f-94d7-cbfd9552a933.png"
  "anatomy.gluteBridge.b|hf_20260711_143246_3b88bd40-7b18-4fe2-aae2-f5ca2e53374c.png"
  "anatomy.dbShoulderPress.a|hf_20260711_143251_410dc7d6-9943-4c13-aca6-3bc7d70480ec.png"
  "anatomy.dbShoulderPress.b|hf_20260711_143306_4035533b-b3b3-4bac-ac75-7273edde9151.png"
  "anatomy.plank.a|hf_20260711_143309_cdc469c5-9540-46df-8798-86bde73e1837.png"
  "anatomy.body.front|hf_20260711_143312_fb1dcd84-e5cb-4e5b-8071-5994b28f411f.png"
  "anatomy.body.back|hf_20260711_143314_c7fca5f7-6058-4d9a-8509-64191feca5e5.png"
)

mkdir -p Anatomy
cat > Anatomy/Contents.json <<'JSON'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

for entry in "${ASSETS[@]}"; do
  name="${entry%%|*}"
  file="${entry##*|}"
  dir="Anatomy/${name}.imageset"
  mkdir -p "$dir"
  echo "→ ${name}"
  curl -fsSL "${BASE}/${file}" -o "${dir}/${name}.png"
  cat > "${dir}/Contents.json" <<JSON
{
  "images" : [
    {
      "filename" : "${name}.png",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON
done

echo "Done — $(ls Anatomy | grep -c imageset) imagesets. Commit ios/Metabolic/Assets.xcassets/Anatomy/ and rebuild."
