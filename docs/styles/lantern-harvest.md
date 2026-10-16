# Lantern & Harvest — the pixel style (saved plan)

**Status:** design approved by Harry on 2026-10-15 (take 3). **Not built.** We do it
together in free time, going through every surface below.

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
6. **One grid, two type sizes.** 2px art pixel. Jersey 15 at 20px for everything, Jersey 10 at 30px only for the clock and titles. Cozette stays in the terminal.
7. **Made by hands.** System icons are Pixelarticons. Portraits are placeholders until we pick human-made ones.
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
- **Motion:** frame-stepped, no easing. Blink at 1–2 fps; the critical toast shakes for 3 frames.

## Assets to fetch at build time

- **Fonts:** Jersey 10 and Jersey 15 (Google Fonts, OFL) → `~/.local/share/fonts/`.
- **Icons:** Pixelarticons 2.4.2 (MIT, Gerrit Halfmann). Only the SVGs we use go in `quickshell/sanctuary/kits/lantern/icons/`, with its LICENSE. Names so far: `terminal globe discord hourglass zap backpack mic mic-off music wifi volume-2 mailbox moon sun cloud cloud-sun bell-ring search book-open chart tea heart`.
- **Portraits:** decide later: a human-made pack, pixel art of real friends, or the app icon only.

## Wallpapers

Harry will use his own wallpaper; the mock's scenes are optional. If wanted: the
rainy roadside **chai dhaba** at night (CHAI neon, kettle, charpai, rider at the
fuel pump) and the same place by day, rendered at 1920×1080 from the mock source.

---

## Inventory — everything that needs a Lantern version

### Quickshell (`quickshell/sanctuary/`), rebuilt as modules on `kits/lantern/`

- [ ] Bar (today SignalBar): workspaces, title, clock, Tracker (TMR), CPU/MEM, mic, music, tray, MSG, Master Caution, recorder cells (SCR / AUD·1 / AUD·2)
- [ ] Toasts + notification centre (SignalToast, SignalCentre)
- [ ] Launcher (+ `:DESK` entries)
- [ ] Style picker (Picker) + Mango layout picker (LayoutPicker)
- [ ] Power menu (PowerMenu)
- [ ] Wallpaper picker (WallPicker, Thumb, FolderGlyph)
- [ ] Tray menus (TrayMenu)
- [ ] Volume OSD (Osd)
- [ ] Music player card (Player)
- [ ] **Recorders:** RIG (Rig), the capture strip (Capture, CapButton), the bar's REC cells. This covers the **meeting recorder** (`scripts/sanctuary/meeting-rec.sh` → the AUD cells and its toasts)
- [ ] Patch bay (Patch)
- [ ] Column strip (Columns)
- [ ] Keys cheat sheet (KeySheet; Keymap.qml text stays)
- [ ] **COMMS card** (CommsCard), the Discord voice card fed by the Vesktop plugin
- [ ] Polkit password prompt (Polkit)
- [ ] Lock screen (Lock / LockSignal → a Lantern face)

### Outside Quickshell

- [ ] kitty `style-lantern.conf` / `style-harvest.conf` (+ tab bar)
- [ ] starship `themes/lantern.toml` / `harvest.toml`
- [ ] niri `layout-lantern.kdl` (pink focus border) · Mango `look-lantern.conf`
- [ ] qutebrowser palette (theme.py style files)
- [ ] **Vesktop:** a Lantern theme next to `vesktop/signal24.theme.css` (the SanctuaryComms plugin is data only, no change)
- [ ] System scheme: Lantern dark, Harvest light (`point_scheme`), so GTK and Brave follow
- [ ] `shell.sh` / `qs.sh`: style table entries (`lantern`, `harvest:lantern`), `point_kit`
- [ ] Wallpaper sides (Harvest = light side)

### Order we agreed to think about

1. Write the kit system and pull a Signal kit out of today's views (Signal must look unchanged).
2. Write `kits/lantern/` and the Lantern/Harvest palettes.
3. Bar → toasts → launcher/picker → everything else in the inventory.
4. Outside apps.
