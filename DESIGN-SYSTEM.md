# The Sanctuary Design System — how to build a module

Read this **before** adding anything to the desktop: a bar cell, a panel, a card,
a gaming module, a study module. `DESIGN-BRIEF.md` says *how the desktop should
feel*; this file says *how to build a piece so it works in every style with the
least code*.

**Status:** written 2026-10-15, before the Lantern build. The rules below are the
target. Today's Quickshell views don't follow them yet (see §8). The Lantern
build is when we migrate.

---

## 1. The goal in one sentence

> **A module is written once and looks right in every style. A style is added
> without touching a single module.**

If adding a style means editing the launcher, the bar, the player and the patch
bay, the system has failed. That's exactly what happens today: `Launcher.qml`
checks the style 30 times and `WallPicker.qml` 31.

### Quick start: the file budget

This is the point of the whole system. If a task needs more files than this,
stop: a kit part is missing, so add it to the kit instead.

| Task | Files you touch | You do NOT touch |
|---|---|---|
| **New module** (study, gaming…) | 1 data singleton (if the data is new) + 1 module file + the plumbing lines (`Ui.qml` flag, `IpcHandler`, script, keybind, `Keymap.qml`, `:DESK` entry) | any style, any kit, any other module |
| **Update a module** | that module file | anything per style |
| **New style** (a whole new look) | `Theme.qml` palette + `kits/<word>/` (the same ~55 files) + the outside-app files + 1 style-table line + 1 picker row | **any module** |
| **New variant** (light/dark printing of a style) | `Theme.qml` palette + 1 style-table line + 1 picker row | the kit, any module |
| **New kit part** (when nothing in §4 fits) | `kits/<every style>/<Part>.qml` + one line in §4 here | modules other than the one that needs it |

You never design a module once per style. The module is written once; each
style already knows how to draw its parts.

---

## 2. Three layers

```
  DATA                    KIT                         MODULES
  what is true            what a style looks like     what you see
  ─────────────           ───────────────────────     ──────────────────
  Sys  Media  Rec         kits/signal/Panel.qml       Bar  Launcher  Player
  Comms  Wm  Notifs   ──▶ kits/signal/Row.qml     ──▶ Patch  Rig  Study
  Tracker  Caution        kits/lantern/Panel.qml      Gaming  …
  (singletons)            kits/lantern/Row.qml …
                          + Theme.qml palette
  no colours, no fonts,   the ONLY files that know    compose kit parts + data;
  no style words          what a style looks like     never ask which style
```

- **Data** is already clean today: `Sys`, `Media`, `Rec`, `Comms`, `Wm`, `Notifs`,
  `Tracker` and `Caution` never mention a style. Keep it that way.
- **Kit** is a small set of parts (§4), one folder per style, with the **same file
  names** in every folder.
- **Modules** are mostly layout: bind data to kit parts.

---

## 3. The module contract — five rules

1. **Never ask which style.** No `Theme.signal`, `Theme.ink`, `Theme.flare`,
   `Theme.word` in a module. If you need one, the kit is missing a part. Add the
   part to every kit instead.
2. **Never pick a colour, font or text size.** Say the state instead (rule 3)
   and let the kit part choose. Colours belong to the style (§5).
3. **Say the state, not the look.** A module says `selected: true`,
   `state: "warn"`, `live: true`, `urgency: "critical"`. The kit decides what
   "warn" looks like: yellow in Signal, orange pips in Lantern.
4. **Never draw a frame, border, shadow or divider yourself.** That's a kit part.
5. **Icons by name.** `Icon { name: "zap" }`. Each kit maps the name to its own
   source: a Nerd Font glyph in Signal, a Pixelarticons SVG in Lantern.

The check before you ship (it must print nothing):

```sh
grep -nE 'Theme\.(signal|ink|flare|light|word)|"#[0-9a-fA-F]{6}"|font\.(family|pixelSize)' <your-module>.qml
```

---

## 4. The kit — the whole vocabulary

The real list, from building Signal's kit (2026-10-16). Each file starts with
a comment saying what it is and its properties; read the kit folder before
writing a new part. **Reuse before you write.** A new style's kit has every
one of these files, each drawn in that style.

| Group | Parts |
|---|---|
| Surfaces | `Panel` (a card: title, detail, hint, tones) · `Plate` (one-line card) · `SidePanel` (tall right-edge panel) · `BarStrip` (the bar's surface and zones) · `ButtonStrip` · `Scrim` · `Fade` (arrive / leave) · `Ticks` (Signal's corner marks) |
| Words | `Label` (by role: body, headline, sub, note, small, fine, tag, readout, empty, none, nomatch, path, caption) · `Heading` · `KeyLine` · `FilterText` · `Value` · `Reading` · `Pair` |
| Rows | `MenuRow` (lists: launcher-style menus, picker, power, RIG, COMMS) · `MenuItem` (app menus) · `ResultRow` (launcher) · `ChannelRow` (patch bay) · `PersonRow` (a call) · `LogRow` (the centre) · `BackRow` · `Rule` |
| Bar | `Cell` · `WsNumber` · `BarClock` · `CautionLamp` · `TrackLine` · `Trace` · `Meter` |
| Controls | `Button` · `Tab` · `ModeTabs` · `Field` · `Prompt` · `StripButton` · `StripReadout` · `StripHint` · `KeyHints` · `FooterBar` · `TitleBar` · `SideHeader` |
| Pictures | `Picture` · `Progress` · `Thumb` · `PhotoTile` · `FolderGlyph` · `Tile` · `Boxes` |
| Whole pieces | `Masthead` (launcher top) · `RegionShade` (capture) · `ToastCard` + `ToastSpec` (toasts) · `Measure` (menu widths) · `LockFace` (the lock screen) |

Two style-free helpers live at the config root, not in the kit: `Popup.qml`
(the overlay window every menu uses: scrim, card, keyboard, list keys) and
`Notice.qml` (one toast's behaviour). Modules use them like kit parts.

States every kit must draw (§5): `tone` / `status` / `labelTone` take
`""`, `"hot"`/`"live"`, `"warn"`, `"alarm"`, `"dim"`, `"soft"`, `"second"`;
rows take `selected`, `current`, `danger`; thresholds (65% / 85%) are inside
`Reading`, `Trace` and `Meter`.

### How a module gets the right kit — one symlink, no code

Switching style already restarts Quickshell (`shell.sh set`), and the outside
apps already switch by symlink (`kitty/style.conf`, `niri/layout.kdl`). The kit
works the same way:

```
quickshell/sanctuary/kit  →  kits/lantern/        (git-ignored symlink, set by shell.sh point_kit)
```

A module just does `import "kit"` and uses `Panel`, `Row`, `Icon`. Variants share
a kit (Flare uses `kits/signal`, Harvest uses `kits/lantern`) and differ only in
`Theme.qml`'s palette. A style with no kit falls back to `kits/signal`, as with
the other files. *(Check at build time that Quickshell's hot reload follows the
directory symlink; if not, a `Loader` per part is the fallback.)*

---

## 5. Colours belong to the style

Each style picks its own palette **and its own rules for what each colour
means**. Signal's are in `DESIGN-BRIEF.md` §4 (colour is spent on state only).
Lantern's are in `docs/styles/lantern-harvest.md` (pink is you, amber is time).
This system doesn't impose one rule on every style.

What every style **does** share is the list of **state words** modules use. Each
kit must have a look for all of them:

`normal` · `dim` · `selected` · `live` · `ok` · `warn` · `alarm` · `critical`

A module says `state: "warn"`. Signal draws it yellow, Lantern draws orange pips,
and any future style draws it its own way. Add a state word here only when a module truly
needs a new one, and give it a look in every kit at the same time.

---

## 6. As little code as possible

- **The module is layout.** Data bindings and kit parts. If a module file
  *draws* (Canvas, Shape, hand-made borders), the drawing belongs in the kit.
  Aim for under ~150 lines.
- **Lists are data.** Rows, menu items, styles and keybinds go in a JS array plus
  a `Repeater`, never as hand-copied blocks. `Picker.qml`'s `styles` array is the
  model to follow.
- **One source of truth for data.** A singleton polls once and everyone reads it,
  the way `Sys` is shared by the bar and the player. A module never starts its own
  process when a singleton could.
- **The same plumbing every time.** UI state in `Ui.qml`, an `IpcHandler` in
  `shell.qml`, a script in `scripts/sanctuary/`, a keybind. Don't invent a new way
  to open things.
- **Outside apps: one file per style plus a symlink**, falling back to Signal's.
  No generators. Already true for kitty, starship, niri and Mango.
- **Style facts in one place.** Light or dark, which kit, which base style: one
  table, not `[ "$1" = flare ]` scattered through `shell.sh`. `qs.sh`'s
  `VARIANTS` line is the start of that table; it should grow into a small
  `styles.conf` (`word base kit scheme`).

---

## 7. Checklists

### A new module (study, gaming, …)

- [ ] **Data:** does a singleton already have it? If not, write one (no colours, no style words).
- [ ] **Plumbing:** `Ui.qml` flag → `IpcHandler` in `shell.qml` → `scripts/sanctuary/<name>.sh` → keybind.
- [ ] **Keys:** a `binds.kdl` change also updates `Keymap.qml`; a new panel also gets a launcher `:DESK` entry.
- [ ] **Bar:** prefer no new bar cell. Toggles go in the launcher `:DESK`. A cell only for something you read all day.
- [ ] **Built only from kit parts.** The grep in §3 prints nothing.
- [ ] **Words** follow the brief's usage profile: readable tired, one keypress, nothing to navigate.
- [ ] **Every style:** switch with Mod+Shift+T and look. Harry does the visual check at the end.

What a module should look like (a study panel, for example):

```qml
import "kit"

Popup {                                         // the overlay window, scrim, keys
    name: "study"
    open: Ui.studyOpen
    onDismissed: Ui.studyOpen = false
    cardWidth: 420

  Panel {
    width: parent.width
    title: "STUDY"
    Repeater {
        model: Study.due                        // data singleton, no style in it
        MenuRow {
            name: modelData.course
            desc: modelData.what
            detail: modelData.when
            status: modelData.hoursLeft < 24 ? "warn" : ""
        }
    }
    Meter { value: Study.weekDone; segments: 10 }   // the kit decides cells / pips / …
  }
}
```

No colours, no fonts, no borders, no style checks. It draws correctly in every
style, including ones that don't exist yet.

### A new style

- [ ] `Theme.qml`: the palette and the style word. Write its colour rules in its own `docs/styles/<word>.md`.
- [ ] `kits/<word>/`: every part in §4, with a look for every state word in §5. A variant (like Harvest) adds only a palette.
- [ ] Style table: base, kit, light or dark scheme, wallpaper side.
- [ ] Outside apps: kitty, starship, niri layout, Mango look, qutebrowser palette, Vesktop theme, wallpaper(s).
- [ ] Picker row.
- [ ] **The test: no module file changed.**

---

## 8. Where we are today (2026-10-16)

**Migrated.** Every view is a module on `kits/signal/` (55 parts), drawn
pixel-identical to before. Each one was checked by rendering old vs new offscreen
and diffing them (`~/Development/pixiecode/runs/2026-10-15_sanctuary-kit-lantern/output/vrt.py`).
The contract grep (§3) finds colours only in `Theme.qml`. Ink and Paper are gone.
`qs.sh` finds styles by their kit folder, and `point_kit` links the right one at start.

Pitfalls met on the way, so the next kit doesn't meet them:
- Don't name a property `left`, `right`, `top`, `state` or `enabled`: Item has them (some FINAL).
- Centre anchors snap to whole pixels; a computed `x` doesn't, so `Math.round` it.
- Keep fractional widths `real` (a measured text width), not `int`.
- Copy a new kit part in before the files that use it: a hot reload can land in between.

**Next: Lantern.** `kits/lantern/` with these same file names, the palettes in
`Theme.qml`, and a `harvest:lantern` variant (`docs/styles/lantern-harvest.md`).
