#!/bin/bash
# Encode portfolio media: posters (JPG), silent autoplay loops, full lightbox versions.
set -e
SRC=~/.openclaw/workspace/projects/_portfolio-src
APP=~/.openclaw/workspace/apps/creative-portfolio
P="$APP/media/posters"; L="$APP/media/loops"; F="$APP/media/full"
mkdir -p "$P" "$L" "$F"

# poster <src> <ts> <name> <width>
poster() { ffmpeg -y -ss "$2" -i "$1" -frames:v 1 -vf "scale=$4:-2" -q:v 3 "$P/$3.jpg" >/dev/null 2>&1 && echo "poster $3"; }
# loop <src> <start> <dur> <name> <width>  (silent, h264, faststart)
loop() { ffmpeg -y -ss "$2" -t "$3" -i "$1" -an -vf "scale=$5:-2" -c:v libx264 -profile:v high -pix_fmt yuv420p -crf 30 -preset veryfast -movflags +faststart "$L/$4.mp4" >/dev/null 2>&1 && echo "loop $4"; }
# full <src> <name> <height> <crf>  (with audio, faststart)
full() { ffmpeg -y -i "$1" -vf "scale=-2:$3" -c:v libx264 -profile:v high -pix_fmt yuv420p -crf "${4:-26}" -preset fast -c:a aac -b:a 128k -movflags +faststart "$F/$2.mp4" >/dev/null 2>&1 && echo "full $2"; }

echo "=== POSTERS ==="
poster "$SRC/toptier.mp4" 60  toptier 1600
poster "$SRC/kitty.mp4"   30  kitty   1600
poster "$SRC/cocka_A.mp4" 55  cocka   1600
poster "$SRC/sol.mp4"     60  sol     1600
poster "$SRC/ramen.mp4"   10  ramen   1600
poster "$SRC/birria.mp4"  30  birria  900
poster "$SRC/cocka_B.mp4" 25  cockaB  1600

echo "=== LOOPS (silent, card autoplay) ==="
loop "$SRC/toptier.mp4" 58  8 toptier 1280
loop "$SRC/kitty.mp4"   28  8 kitty   1280
loop "$SRC/cocka_A.mp4" 50  8 cocka   1280
loop "$SRC/sol.mp4"     55  8 sol     1280
loop "$SRC/ramen.mp4"   8   8 ramen   1280
loop "$SRC/birria.mp4"  28  8 birria  720
loop "$SRC/cocka_B.mp4" 22  8 cockaB  1280

echo "=== FULL (lightbox, with audio) ==="
full "$SRC/toptier.mp4" toptier 1080 26
full "$SRC/kitty.mp4"   kitty   1080 27
full "$SRC/cocka_A.mp4" cocka   1080 26
full "$SRC/sol.mp4"     sol     1080 27
full "$SRC/ramen.mp4"   ramen   1080 27
full "$SRC/birria.mp4"  birria  1280 27
full "$SRC/cocka_B.mp4" cockaB  1080 26

echo "=== DONE ==="
du -sh "$P" "$L" "$F"
