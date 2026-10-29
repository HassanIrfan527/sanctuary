# Lantern & Harvest — the pixel style (saved plan)

**Status:** design approved by Harry on 2026-10-15 (take 3). **Built 2026-10-16:**
Quickshell (`quickshell/sanctuary/kits/lantern/`), then the outside apps, the
pixel cursor and the GTK layer (list below).

Decided at build time (Harry, 2026-10-16):
- **Portraits:** the notification's own picture, drawn in fat pixels (3×); with
  no picture, the app's Pixelarticon. Nothing invented.
- **Motion: none.** Everything appears and disappears at once. No blink, no
  glove, no shake. (The time-left line and gauges still move: they are readings.)
- **Wallpapers:** his own. The dhaba scene stays in the mock.
- **Clock and titles** use Jersey 10 at **32px**, not 30: at 30 Qt draws its
  pixels unevenly, at 32 they are clean.
- **Cursor:** Pixel Cursors by mikaeladev (GPL-3.0, 12px hand-drawn; some art
  from shmorgus' Micro Icon Pack), recoloured cream / pink / wood, at 2× (24px).
  Built by `scripts/sanctuary/pixel-cursors.py` into `~/.local/share/icons/`
  (`Lantern-Pixel`, `Harvest-Pixel`); kept out of git, the art isn't ours to publish.
- **GTK 3/4:** no pixel GTK theme exists, so `gtk/` is ours: GTK3 themes Lantern /
  Harvest on adw-gtk3, and `gtk/gtk4/<style>.css` for libadwaita. Colours + pixel
  shape (square, 2px frames, wooden buttons, pink selection); the normal UI font.
- **Fonts elsewhere:** kitty in Cozette (13px); Vesktop entirely in Jersey;
  qutebrowser's bars stay DM Mono. `fontconfig/conf.d/60-jersey-pixel.conf`
  draws Jersey unsmoothed outside Qt too.
- **Windows don't animate** under Lantern / Harvest (niri `animations { off }`): the same "no motion" decision.

- Mock (live, animated): https://claude.ai/artifact/L6t3uEP64n4hzBRe5yv5vs
- Mock source: `~/Development/pixiecode/runs/2026-10-15_pixel-theme-v2/output/src/`
  (`lantern3.src.html` + `build3.py`; the scene code is in `lantern.src.html`)
- Build it on the module system in `../../DESIGN-SYSTEM.md`: a `kits/lantern/`, not
  a `LanternBar.qml` copy of every view.

**Lantern** is the night version. **Harvest** is the same place on an autumn
afternoon. References: Travellers Rest and Stardew Valley (wood and parchment,
warm light), Valenberg's video for Perturbator's *Sentient* (rain, neon, light on
wet streets). No taverns or alcohol anywhere.

---

## Philosophy (the 8 rules)

1. **Cozy at rest, bright when it matters.** Calm wood and ink; colour only when something is live.
2. **Every colour has one job.** Pink is **you** (focus, selection, unread). Amber is light and time. Green, orange and red are the machine. Cyan is sound.
3. **Three materials, never more.** Wood frames, paper holds, slots are sunk into the paper.
4. **Things, not labels.** CPU = ⚡ energy, memory = backpack, messages = mailbox, workspaces = a toolbar.
5. **Fewer boxes, more rhythm.** Spacing separates, not boxes.
6. **One grid, two type sizes.** 2px art pixel. Jersey 15 at 20px for everything, Jersey 10 at 32px only for the clock and titles. Cozette stays in the terminal.
7. **Made by hands.** System icons are Pixelarticons. A portrait is the notification's own picture, or the app's icon.
8. **Same place, different hour.** Lantern and Harvest share every position and shape.

## Colours

| Role | Lantern | Harvest |
|---|---|---|
| pink · you | `#ff5c9d` (6.1:1 on ink) | `#b8286c` (4.6:1 on parchment) |
| amber · light | `#ffb347`, lamp `#ffd68a` | `#a8561a`, lamp `#c56a1a` |
| ok / warn / alarm | `#7fc45a` / `#f08a3c` / `#e8423f` | `#3f8a2e` / `#c56a1a` / `#a82418` (brick, kept apart from pink) |
| cyan · sound | `#5fd3e0` | `#2f6fa0` |
| paper (ink at night) | `#1a1630`, sunk `#0f0c1e`, raised `#2c2650` | `#f6e2b3`, sunk `#d9b77c`, raised `#fff0cc` |
| text / dim / bright | `#f2dcb0` / `#9d8cb0` / `#fff0cc` | `#4a2a1e` / `#8a5a3a` / `#2a160f` |
| wood: outline · dark · body · side · lit · nail | `#1e1216 #3a2422 #553226 #6a3e2b #8f5a36 #c99a5b` | `#3a2018 #7a4a2c #9c6236 #b0713e #dba05a #f7d58c` |

## Shapes

- **Bar:** one wooden rail around one sunk strip, 44px, three zones: *where* (workspace slots with the app's icon, the focused one with a pink frame and corner marks, then the window title) · *when* (the raised amber clock plaque: moon/sun, `THU 15`, `10:41`, weather) · *how* (hourglass timer, ⚡ pips, backpack pips, mic LIVE, now playing, wifi + volume, then a wooden post and the mailbox with a pink badge). Gauges: 8 pips, orange at 65%, red at 85%.
- **Toast:** one wood frame, the portrait in a sunk slot inside it, the sender's name on a pink tab over the top edge, a header line with app and time, a thin pink line for time left, and a pink primary button. Critical: red tab, frame, header and portrait.
- **Lists** (launcher, picker, power, patch, tray menu, keys): shop-style rows with an icon slot, the name, and detail on the right. The selected row is raised, with a pink icon and the glove cursor.
- **Windows:** niri focus border in pink.
- **Motion:** none (Harry, 2026-10-16). The mock's blinks and shake are not built.

## Assets to fetch at build time

- **Fonts:** Jersey 10 and Jersey 15 (Google Fonts, OFL) → `~/.local/share/fonts/`.
- **Icons:** Pixelarticons 2.4.2 (MIT, Gerrit Halfmann). Only the SVGs we use go in `quickshell/sanctuary/kits/lantern/icons/`, with its LICENSE. Names so far: `terminal globe discord hourglass zap backpack mic mic-off music wifi volume-2 mailbox moon sun cloud cloud-sun bell-ring search book-open chart tea heart`.
- **Portraits:** decided: the notification's image in fat pixels, else the app icon.

## Wallpapers

Harry will use his own wallpaper; the mock's scenes are optional. If wanted: the
rainy roadside **chai dhaba** at night (CHAI neon, kettle, charpai, rider at the
fuel pump) and the same place by day, rendered at 1920×1080 from the mock source.

---

## Inventory — everything that needs a Lantern version

### Quickshell (`quickshell/sanctuary/`), rebuilt as modules on `kits/lantern/`

- [x] Bar (today SignalBar): workspaces, title, clock, Tracker (TMR), CPU/MEM, mic, music, tray, MSG, Master Caution, recorder cells (SCR / AUD·1 / AUD·2)
- [x] Toasts + notification centre (SignalToast, SignalCentre)
- [x] Launcher (+ `:DESK` entries)
- [x] Style picker (Picker)
- [x] Power menu (PowerMenu)
- [x] Wallpaper picker (WallPicker, Thumb, FolderGlyph)
- [x] Tray menus (TrayMenu)
- [x] Volume OSD (Osd)
- [x] Music player card (Player)
- [x] **Recorders:** RIG (Rig), the capture strip (Capture, CapButton), the bar's REC cells. This covers the **meeting recorder** (`scripts/sanctuary/meeting-rec.sh` → the AUD cells and its toasts)
- [x] Patch bay (Patch)
- [x] Column strip (Columns)
- [x] Keys cheat sheet (KeySheet; Keymap.qml text stays)
- [x] **COMMS card** (CommsCard), the Discord voice card fed by the Vesktop plugin
- [x] Polkit password prompt (Polkit)
- [x] Lock screen (Lock / LockSignal → a Lantern face)

### Outside Quickshell

- [x] kitty `style-lantern.conf` / `style-harvest.conf` (tab_bar.py reads the colours)
- [x] starship `themes/lantern.toml` / `harvest.toml`
- [x] niri `layout-lantern.kdl` / `-harvest` (4px pink focus border, cursor, no animation)
- [x] qutebrowser palette (`theme.py`: `_lantern`, `_harvest`)
- [x] **Vesktop:** `vesktop/lantern24.theme.css`; Vesktop enables `themes/sanctuary.theme.css`, which shell.sh points at signal24 or lantern24
- [x] System scheme: Lantern dark, Harvest light (`point_scheme`), plus the GTK theme, libadwaita CSS and cursor
- [x] `shell.sh` / `qs.sh`: style table entries (`lantern`, `harvest:lantern`), `point_kit`
- [x] Wallpaper sides (Harvest = light side: `is_light` in shell.sh)

### Order we agreed to think about

1. Write the kit system and pull a Signal kit out of today's views (Signal must look unchanged).
2. Write `kits/lantern/` and the Lantern/Harvest palettes.
3. Bar → toasts → launcher/picker → everything else in the inventory.
4. Outside apps.
