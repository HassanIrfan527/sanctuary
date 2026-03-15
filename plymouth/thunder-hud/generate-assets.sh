#!/bin/bash
# Generate all PNG assets for Thunder HUD Plymouth theme
# Requires: ImageMagick 7 (magick command)

DIR="$(cd "$(dirname "$0")" && pwd)"
GREEN="#00ff41"
DIM_GREEN="#0a3d0a"
DARK_GREEN="#003300"
AMBER="#ff8c00"
W=1920
H=1080

echo "Generating Thunder HUD Plymouth assets..."

# ── Background (pure black) ──
magick -size ${W}x${H} xc:black "$DIR/background.png"
echo "  [1/13] background.png"

# ── Scanline (thin green horizontal line) ──
magick -size ${W}x2 xc:"$GREEN" -channel A -evaluate set 70% "$DIR/scanline.png"
echo "  [2/13] scanline.png"

# ── HUD Border Frame ──
magick -size ${W}x${H} xc:none \
  -stroke "$GREEN" -strokewidth 1 -fill none \
  -draw "rectangle 60,40 1860,1040" \
  -stroke "$GREEN" -strokewidth 2 \
  -draw "line 60,40 100,40" -draw "line 60,40 60,80" \
  -draw "line 1860,40 1820,40" -draw "line 1860,40 1860,80" \
  -draw "line 60,1040 100,1040" -draw "line 60,1040 60,1000" \
  -draw "line 1860,1040 1820,1040" -draw "line 1860,1040 1860,1000" \
  -strokewidth 1 \
  $(for i in $(seq 100 40 1820); do echo "-draw 'line $i,40 $i,48'"; done) \
  $(for i in $(seq 100 40 1820); do echo "-draw 'line $i,1040 $i,1032'"; done) \
  $(for i in $(seq 80 40 1000); do echo "-draw 'line 60,$i 68,$i'"; done) \
  $(for i in $(seq 80 40 1000); do echo "-draw 'line 1860,$i 1852,$i'"; done) \
  "$DIR/hud-border.png"
echo "  [3/13] hud-border.png"

# ── Crosshair (central targeting reticle) ──
magick -size 400x400 xc:none \
  -stroke "$GREEN" -strokewidth 1 -fill none \
  -draw "line 200,0 200,150" \
  -draw "line 200,250 200,400" \
  -draw "line 0,200 150,200" \
  -draw "line 250,200 400,200" \
  -strokewidth 1 \
  -draw "line 180,150 180,170" -draw "line 180,170 150,170" \
  -draw "line 220,150 220,170" -draw "line 220,170 250,170" \
  -draw "line 180,250 180,230" -draw "line 180,230 150,230" \
  -draw "line 220,250 220,230" -draw "line 220,230 250,230" \
  -draw "circle 200,200 200,160" \
  -strokewidth 1 \
  -draw "line 170,200 180,200" \
  -draw "line 220,200 230,200" \
  -draw "line 200,170 200,180" \
  -draw "line 200,220 200,230" \
  "$DIR/crosshair.png"
echo "  [4/13] crosshair.png"

# ── Crosshair Rotating Ring ──
magick -size 420x420 xc:none \
  -stroke "$GREEN" -strokewidth 1 -fill none \
  -draw "arc 10,10 410,410 0,90" \
  -draw "arc 10,10 410,410 120,210" \
  -draw "arc 10,10 410,410 240,330" \
  "$DIR/crosshair-ring.png"
echo "  [5/13] crosshair-ring.png"

# ── Crosshair Brackets (pulsing corners) ──
magick -size 300x300 xc:none \
  -stroke "$GREEN" -strokewidth 2 -fill none \
  -draw "line 20,20 60,20" -draw "line 20,20 20,60" \
  -draw "line 280,20 240,20" -draw "line 280,20 280,60" \
  -draw "line 20,280 60,280" -draw "line 20,280 20,240" \
  -draw "line 280,280 240,280" -draw "line 280,280 280,240" \
  "$DIR/crosshair-brackets.png"
echo "  [6/13] crosshair-brackets.png"

# ── Fighter Jet Silhouette ──
magick -size 200x100 xc:none \
  -fill "$GREEN" -stroke none \
  -draw "polygon 100,10 120,30 180,40 190,45 190,55 180,60 120,70 100,90 80,70 20,60 10,55 10,45 20,40 80,30" \
  -draw "polygon 95,25 105,25 105,85 95,85" \
  -draw "polygon 60,45 140,45 140,55 60,55" \
  "$DIR/air-icon.png"
echo "  [7/13] air-icon.png"

# ── Tank Silhouette ──
magick -size 200x100 xc:none \
  -fill "$GREEN" -stroke none \
  -draw "roundrectangle 30,50 170,85 5,5" \
  -draw "roundrectangle 50,30 130,55 3,3" \
  -draw "rectangle 120,35 175,42" \
  -draw "ellipse 55,85 12,12 0,360" \
  -draw "ellipse 85,85 12,12 0,360" \
  -draw "ellipse 115,85 12,12 0,360" \
  -draw "ellipse 145,85 12,12 0,360" \
  -fill none -stroke "$GREEN" -strokewidth 1 \
  -draw "roundrectangle 25,78 175,92 8,8" \
  "$DIR/land-icon.png"
echo "  [8/13] land-icon.png"

# ── Battleship Silhouette ──
magick -size 200x100 xc:none \
  -fill "$GREEN" -stroke none \
  -draw "polygon 10,60 40,50 160,50 190,60 170,70 30,70" \
  -draw "rectangle 60,35 140,52" \
  -draw "rectangle 85,20 115,37" \
  -draw "rectangle 95,10 105,22" \
  -draw "rectangle 50,42 55,52" \
  -draw "rectangle 145,42 150,52" \
  -fill none -stroke "$GREEN" -strokewidth 1 \
  -draw "line 10,60 190,60" \
  "$DIR/sea-icon.png"
echo "  [9/13] sea-icon.png"

# ── Compass Strip ──
magick -size 800x40 xc:none \
  -stroke "$GREEN" -strokewidth 1 -fill none \
  -draw "line 0,20 800,20" \
  $(for i in $(seq 0 20 800); do echo "-draw 'line $i,15 $i,25'"; done) \
  $(for i in $(seq 0 100 800); do echo "-draw 'line $i,10 $i,30'"; done) \
  -fill "$GREEN" -pointsize 12 -font "JetBrains-Mono" \
  -draw "text 0,38 'W'" \
  -draw "text 195,38 'N'" \
  -draw "text 395,38 'E'" \
  -draw "text 595,38 'S'" \
  -draw "text 790,38 'W'" \
  -draw "text 95,38 '315'" \
  -draw "text 295,38 '045'" \
  -draw "text 495,38 '135'" \
  -draw "text 695,38 '225'" \
  -fill "$GREEN" \
  -draw "polygon 400,0 395,8 405,8" \
  "$DIR/compass.png"
echo "  [10/13] compass.png"

# ── Progress Bar Background ──
magick -size 600x20 xc:none \
  -stroke "$DIM_GREEN" -strokewidth 1 -fill none \
  -draw "roundrectangle 0,0 599,19 3,3" \
  $(for i in $(seq 0 30 600); do echo "-draw 'line $i,0 $i,19'"; done) \
  "$DIR/progress-bar-bg.png"
echo "  [11/13] progress-bar-bg.png"

# ── Progress Bar Fill ──
magick -size 600x20 xc:none \
  -fill "$GREEN" -stroke none \
  -draw "roundrectangle 1,1 598,18 2,2" \
  "$DIR/progress-bar-fill.png"
echo "  [12/13] progress-bar-fill.png"

# ── Vehicle Diagnostic Panel Frame ──
magick -size 200x160 xc:none \
  -stroke "$GREEN" -strokewidth 1 -fill none \
  -draw "rectangle 0,0 199,159" \
  -draw "line 0,25 199,25" \
  -strokewidth 1 \
  -draw "line 5,0 15,0" -draw "line 0,5 0,15" \
  -draw "line 185,0 199,0" -draw "line 199,5 199,15" \
  -draw "line 5,159 15,159" -draw "line 0,145 0,159" \
  -draw "line 185,159 199,159" -draw "line 199,145 199,159" \
  "$DIR/panel-frame.png"
echo "  [13/13] panel-frame.png"

echo ""
echo "All assets generated in: $DIR"
echo "Total files: $(ls -1 "$DIR"/*.png | wc -l) PNGs"
