# The Sanctuary — Design Brief

Reference for anyone (human or agent) designing or building components for this desktop.
Read this **before** writing any config, CSS, or theme file.

Companion to `DESKTOP-PLAN.md` (what we're building, in what order). This file is
**how it should look and behave**.

**Status:** direction settled. Bar, launcher, notifications, wallpaper, lock and night light built.
Launcher is **walker** as of 2026-09-22 (a terminal launcher was built the same day and turned
down — §3). fuzzel kept installed as the fallback. noctalia removed from every config. SDDM
theming unstarted.
**Updated:** 2026-09-25

---

## 1. Usage profile — read this first

The design serves this. Not the other way around.

**The operator is usually tired.** Burnout and exhaustion are the normal operating state, not
the exception:

- Low GUI usage. Does not browse menus or click around panels.
- **Also low terminal usage.** "Just drop to a TUI" is not an acceptable answer for anything
  done *regularly*. It is fine for rare, deep operations only.
- Reads the screen far more than interacting with it.

### The governing rule

> **The bar reports. Keybinds act. Nothing requires navigation.**

Anything touched regularly must be either already visible, or a single keypress with no menu to
walk through. If a design requires opening something, finding something inside it, then acting
— it is wrong for this user.

### Observed behaviour

| Behaviour | Design consequence |
|---|---|
| Watches notification toasts pass by; rarely opens a centre | Toasts legible at a glance. |
| Occasionally opens the centre only to clear everything | Clear-all is one keybind, **and** a `[ clear all ]` button in the centre. |
| Changes wallpaper ~weekly, chooses visually | Picker needs real image previews, keyboard-navigable, no typing filenames. |
| Wants mic state visible, toggles by keybind | Mic is a **readout**, not a button. |
| Clipboard "good but optional" | Keybind only. Not on the bar. |
| Keyboard-first, vim-obsessed | Every action has a keybind. Mouse is fallback, never primary. |

### Non-goals

- ~~No notification centre / history panel~~ — **reversed 2026-09-22.** Harry asked for a full
  ASCII centre directly, twice. The observation behind the old rule (he mostly clears the stack)
  still holds, so the centre is built to make clearing instant rather than to be browsed — but it
  exists, and it is swaync. See §5.
- No GUI audio mixer, wifi picker, bluetooth panel, calendar widget
- No dashboard, no widget grid, no "command centre"
- No hover-to-reveal — if it matters it's visible, if it doesn't it's a keybind

---

## 2. Direction — TUI-native

> **"Everything should be controlled by keyboard, and the whole OS is vim."**
> — `README.md`, written long before this plan existed.

The file manager is yazi. The monitor is btop. Git is lazygit. The editor is nvim. It all lives
in tmux. **This system is already a TUI.** The desktop chrome should look like the rest of the
computer instead of arguing with it.

So: the bar is a **row of TUI panels**. Notifications are bordered boxes. The launcher is a
terminal. Every surface looks like it could be running inside tmux, because most of it is.

### Why this settles "rounded or square"

Square. Not by preference — by consequence. Box-drawing is square, terminals are square, so the
philosophy decides it and the question stops being a question. Corner radius is **0–2px**
everywhere. This was previously an unresolvable coin-flip; committing to TUI resolved it.

**One scoped exception, added 2026-09-25: Zen mode.** Windows round to **12px** and the zen bar's
clock is a soft pill, because zen is the mode where the screen holds *one* thing — and structure
earns its keep by separating things. With nothing to separate, a drawn frame is decoration.
Default mode is unchanged and still square. The exception is a *mode*, not a revision: it lives in
`scripts/sanctuary/modes/zen.conf`, so it cannot leak into the rest of the system by accident.
Known cost, accepted: at 12px with `clip-to-geometry true`, the corner character cell of a
bordered TUI gets nibbled.

### Rules

| Axis | Rule |
|---|---|
| **Structure** | Islands, not transparency. Every module is a bordered box with a fill. Visible structure *is* the craft. |
| **Shape** | 0–2px radius. Square. One exception, Zen mode — see above. |
| **Type** | Monospace only — JetBrainsMono Nerd Font. One family, whole system. |
| **Glyphs** | ASCII and block characters over icon fonts: `█ ░ ▓ ▒ ● ○ ▶ ‖ [ ]`. Text labels where a word fits (`mic on`, not a microphone icon). |
| **Colour** | Per-module accent borders carry identity — you tell modules apart by border colour without reading them. |
| **Motion** | Short, ease-out, ~160ms. Nothing bounces. |
| **Empty states** | Render *nothing*. Never a greyed placeholder. |

---

## 3. Rejected directions

Recorded so they don't get re-proposed. Both were tried and turned down.

**Transparent text bar (no islands, no backgrounds).** Built, run, rejected. Harry had already
built this exact thing in an earlier rice and abandoned it. The failure: restraint isn't craft,
it's absence — and absence is what didn't work the first time. **Islands are non-negotiable.**

**"Ember" / monastic minimalism** — warm amber accent, rationed light, emptiness as the primary
material. Rejected: *"i don't think that ember thing is gonna stand out."* The brief asked for
nothingness **and** beauty; that direction delivered only the first half.

**What survived from it:** the burnout rule in §1, empty-states-render-nothing, and mic-live
earning an accent. Everything else is gone.

**Terminal launcher (fzf in a floating kitty).** Built, run, rejected — 2026-09-22, the same day
as the fuzzel→walker move. It worked and it looked right: a drawn `┌─ the sanctuary ─┐` frame, a
live `apps / up / load` banner, `█`/`░` down the gutter, aligned columns, desktop-entry actions,
launch-count ordering. It is kept unbound at `scripts/sanctuary/run.sh`.

Rejected for two reasons, and the look was not one of them:

1. **~400ms to open**, against fuzzel's ~20ms, because a terminal has to boot first. The only fix
   was a resident kitty at ~120MB, which fails DESKTOP-PLAN.md §1.
2. **"we're overcomplicating things."** 250 lines of shell, an awk `.desktop` parser, a launch
   history file and a niri window rule, to open applications. Harry's words: *"no i dont like the
   terminal one. just use walker."*

**The lesson, and it is the reusable one:** "the desktop should look like a TUI" (§2) is about the
*visual language* — square, monospace, block glyphs, bracketed labels — **not** about literally
running things in terminals. A GTK4 launcher with a hand-written widget tree reaches ~90% of the
same look in 3 config files and opens in 80ms. Do not reach for a terminal again just because a
surface needs to look like characters; reach for it when the thing genuinely is text.

**Do not re-propose minimal/transparent/monochrome chrome.** It has been tested against this
user twice and failed twice.

---

## 4. Tokens

### Colour — Catppuccin Mocha

Already what niri runs, and squarely Harry's stated taste (lavender, peach, light green, muted).
No matugen — generated palettes are muddy and unpredictable.

```
crust     #11111b    island fill
mantle    #181825    alternate fill
base      #1e1e2e    
surface0  #313244    neutral borders
surface1  #45475a    
surface2  #585b70    inactive glyphs

overlay0  #6c7086    de-emphasized text
subtext0  #a6adc8    secondary text
text      #cdd6f4    primary text

lavender  #b4befe    music / structure
mauve     #cba6f7    workspaces
peach     #fab387    clock, notifications
green     #a6e3a1    mic live, "all is well"
yellow    #f9e2af    
red       #f38ba8    urgent only
```

**Border colour is identity.** A module's accent border is how it's recognised without reading
it. Neutral (`surface0/1`) means nothing to report.

### Space, shape, motion

```
radius       0-2px     islands (0 for bar, 2px acceptable elsewhere)
border       1px       always visible, always coloured
bar-height   36px
margin       4px top, 8px sides    islands float clear of screen edge
module-gap   3px
font-size    12px  (10-11px for glyph-only modules)
duration     160ms
easing       ease-out
```

Space is per **mode** as of 2026-09-25 — these are the numbers, and they live in
`scripts/sanctuary/modes/<name>.conf`, not in any KDL file:

| | Default | Zen | Zen — no bar |
|---|---|---|---|
| gaps | 4 | 16 | 16 |
| struts (side / top / bottom) | 8 / 8 / 8 | 40 / 20 / 32 | 40 / 40 / 40 |
| window radius | 2 | 12 | 12 |
| window opacity | 1.0 | 0.97 | 0.97 |
| centre a lone window | no | yes | yes |
| bar | full | clock pill | none (Mod+Shift+A peeks) |
| bar blur | no | yes | yes |
| notifications | on | DND | DND |

---

## 5. Component specs

### Bar (waybar) — BUILT

`~/.dotfiles/waybar/{config.jsonc,style.css}`. Variants A and B kept in `variants/` for
reference.

```
┌─────────┐                    ┌──────────────┐          ┌───────────────────┐ ┌────────────┐   ┌───────┐ ┌─────┐
│ ⠶ ⣿ ⠶ ⠶│                  │[ 05:27 PM Tue 22]│          │ ▶ KAWAI YUTO — …  │ │ [ mic on ] │ │ │ tray  │ │ [▃] │
└─────────┘                    └──────────────┘          └───────────────────┘ └────────────┘   └───────┘ └─────┘
   mauve                            peach                       lavender            green      sep neutral  peach
```

The clock sits **centre**: it is the one module read without being looked for.
Everything actionable is right, where the pointer already is, and the
notification block is dead last so it never moves when something else changes
width.

**Islands are drawn frames as of 2026-09-25, not bordered widgets.** A plain 1px accent
rectangle is what every GTK bar looks like; a TUI panel is a dim rule with a brighter corner.
Each island is now painted as **12 background layers** — four edges in `surface1` plus eight
corner arms (8×1px and 1×8px) in the module's accent — so it reads as `┌───┐` and the accent
lives in the corners instead of shouting round the whole outline. GTK3 has no pseudo-elements,
so multiple background layers with independent `background-size`/`background-position` are the
only way to mark a corner. Cost, accepted: GTK cannot transition a gradient, so frame state
changes snap; text colour still fades at 160ms, and that is the part the eye tracks.

**Punctuation is structure, not content.** Brackets, the field divider and the module's own
label drop to `#45475a`/`overlay0` via pango markup, while the value keeps the accent — you read
`10:04` before you read `[`, and `on` before you read `mic`. For the clock the markup is written
*inside* the strftime spec, which works because strftime passes anything that is not a `%` escape
straight through.

| Module | Spec |
|---|---|
| **Workspaces** | **Braille cells since 2026-09-25**: `⣿` focused / `⠶` idle / `⣶` urgent, mauve. Dot density carries the state and the colour confirms it; 15px, 5px button padding, because braille needs the points to read as dots. The block pair `█`/`░` it replaced is still the house language everywhere else (launcher gutter, notification meter, volume meter) — this module just says it in braille. **Non-optional:** the glyphs are wrapped in `<span font_family='CommitMono Nerd Font'>` — see the font trap below. |
| **Clock** | `[ 10:04 AM │ Fri 25 ]`, peach, **centred**. Two-tone: time in full peach, meridiem `overlay0`, date `subtext0`, brackets and divider at frame grey. 12-hour; `%I` is zero-padded and `%p` fixed-width, so the island never changes width and its neighbours never shuffle. |
| **Music** | `▶ ▓▓▓░░░░░ │ title — artist`, 34ch truncation, lavender. The 8-cell position meter (2026-09-25) is the workspace block language reused — filled `subtext0`, empty frame grey — and renders nothing when the player reports no `mpris:length`, because a meter stuck at 0 is a lie. Title leads, so a long entry clips the artist and keeps the track name. Dims when paused. Click toggles playback, scroll skips. Right-click is deliberately unbound — a floating player TUI is the eventual answer, not a popup. |
| **Mic** | `[ mic on ]` green / `[ mic -- ]` neutral. A readout first: **right-click** cuts the mic, **left-click** opens `wiremix` as a floating terminal. `Mod+M` is the real interface. |
| **Separator** | `│` in `surface1`, no fill, no border. Splits the right side into an audio cluster and a system cluster. |
| **Tray** | Neutral border. **Unsolved — see §7.** |
| **Notifications** | Rising block by queue depth — `▁ ▃ ▅ ▇ █` for 1/2/3/4/5+, peach, far right. Click toggles the centre, right-click toggles DND. **The one module that stays visible when empty** (dim `[ ░ ]`): it is the click target for the centre, and an affordance you cannot see is one you cannot press. |
| **Volume** | **Off the bar since 2026-09-22.** `scripts/volume.sh` still works and the `[ vol ████░░░ ]` meter is intact if it is ever wanted back; volume now lives on the keybinds and in `wiremix`. |

**NixOS gotcha:** the binary is wrapped — `pkill -x waybar` matches nothing. Use
`pkill -x .waybar-wrapped`. Stacked invisible instances caused a long debug detour once already.
**This applies to every wrapped binary here**, and it cuts both ways: `pgrep -x noctalia`
returns nothing while noctalia is very much running as `.noctalia-wrapp`. So does `pgrep -x
swaync` (`.swaync-wrapped`) and `pgrep -x awww-daemon` (`.awww-daemon-wr` — comm is truncated at
15 characters, so even the full wrapped name does not match). This has caused a wrong "it is not
running" conclusion four separate times.

**Rule: never check a daemon's liveness by process name here.** Ask the daemon — `awww query`,
`swaync-client -c`. `wallpaper.sh` does exactly this; checking by name started a second daemon
that core-dumped.

**niri: do not put `place-within-backdrop true` on the wallpaper daemon's layer rule.** It moves
the background surface into the overview backdrop, so it stops being drawn on the normal
workspace view — the wallpaper disappears entirely until you open the overview, while
`awww query` still reports it as displaying. Diagnosed the hard way.

**`wl-copy` must stay resident** — it owns the Wayland selection until something replaces it —
so anything running it inside a terminal keeps that terminal alive. `clipboard.sh` wraps it in
`setsid`; without that the picker window never closes after you pick something.

**Muting:** borders are the accent mixed ~45% into `surface0` (`@define-color b_lavender
mix(@lavender, @surface0, 0.45)` and friends). Identity survives, nothing shouts. Text keeps the
full accent, because text has to be read. Mauve needed 0.55 — it is a light hue and read brighter
than the rest at 0.45.

**GTK3 gotchas** (waybar's CSS is GTK3, not a browser):
- No `var()` — CSS custom properties do not exist. `@define-color` covers colours only, so
  radius/spacing/duration tokens are written literally.
- `@keyframes` will not take comma-joined selectors. `0%, 100% { }` fails to parse with
  *"Expected closing bracket after keyframes block"*; use `from`/`to` plus `alternate`.
- Colour expressions (`mix()`, `alpha()`, `shade()`) *are* allowed inside `@define-color`.
- **JetBrainsMono Nerd Font has zero braille coverage** (`fc-list 'JetBrainsMono Nerd Font:charset=28ff'`
  returns nothing). The per-glyph fallback then draws *every* braille codepoint as the same 8-dot
  grid, so `⠄ ⠆ ⠶ ⠿ ⣿` all come out identical and any braille meter is meaningless — it looks like
  it rendered, which is why this took four test rounds to spot. Naming a braille-capable font in
  the pango markup (`<span font_family='CommitMono Nerd Font'>`) fixes it per glyph and leaves the
  rest of the bar on JetBrainsMono. A CSS `font-family` on the module works too, but the markup
  route keeps the exception where the exception is. Installed fonts with braille: CommitMono Nerd
  Font, Maple Mono NF, DejaVu, FreeMono, Cozette.
- Multiple background layers **do** work, with per-layer `background-size` / `background-position`
  / `background-repeat`. This is what draws the corner frames; first layer paints on top.
- Gradients **cannot** be transitioned. Anything that must fade has to ride on `color` or
  `background-color`.
- A `#workspaces button` keeps the GTK theme's corner radius unless you set `border-radius: 0`
  on it explicitly — an inverse-video active cell comes out rounded otherwise.

### Notifications + centre (swaync) — BUILT, not yet switched on

`~/.dotfiles/swaync/swaync/{config.json,style.css}`, symlinked to `~/.config/swaync`.

**Why swaync and not mako.** mako physically cannot host a centre — it is a toast daemon with a
small `restore` ring buffer and no panel surface of any kind. swaync is a notification centre by
definition and was already installed. It replaces mako outright: one daemon for both toasts and
the panel, one stylesheet for both. The mako config is kept at `~/.dotfiles/mako/mako/config`,
inactive, as the fallback if the centre turns out to be the mistake the old §1 predicted.

| Surface | Treatment |
|---|---|
| **Centre** | One island: crust fill, 1px muted-lavender border, radius 0, top-right under the bar (`margin-top: 44`). |
| **Header** | `[ notifications ]` with a `[ clear all ]` button — real bracket characters, set as label text in `config.json`, not drawn boxes. |
| **DND** | `[ do not disturb ]` with the GTK switch restyled square: a `█` block sliding inside a `[ ]`. Peach when on. |
| **Cards** | crust fill, 1px `surface1` border, and a 2px **left stripe** carrying urgency — `surface1` low, muted lavender normal, red critical. Border colour is identity, same rule as the bar. |
| **Close** | Square 1px box per card, red on hover. |
| **Actions** | An actionable notification's buttons render as bracketed squares in lavender. This is the "click" affordance. |
| **Empty** | `— nothing waiting —`. |
| **Artwork** | Off everywhere — `image-visibility: never` plus every icon-size knob at 0. Same reasoning as the tray in §7. |
| **Motion** | `transition-time: 160`, matching the bar. |

Keybinds: **Mod+Shift+D** toggle the centre, **Mod+Ctrl+D** close all, **Mod+Alt+D** DND.

The waybar module now streams from `swaync-client -swb` instead of polling — event-driven, no
interval — and gains a `.dnd` class that mutes the block while DND is on.

**Two GTK4 traps hit while styling it**, both fixed, both worth knowing: GTK sizes a `slider`
from its parent's *content* box, so a tight `switch` or `scrollbar` makes the slider compute
negative (`GtkGizmo reported min width -13`) — give the parent room. And GTK has no `content:`
property, so an icon cannot be swapped for text from CSS; the close button's ASCII reading comes
from the square border around its symbolic glyph, not from replacing it.

**Still inactive.** noctalia owns `org.freedesktop.Notifications`, so swaync exits with *"Could
not acquire notification name"*. Verified as far as that point: both `config.json` and
`style.css` load with zero parse errors.

### Launcher (walker + elephant) — BUILT · 2026-09-22

`~/.dotfiles/walker/walker/`, stowed to `~/.config/walker`. **Mod+Space.** fuzzel stays installed
and **Mod+Shift+Space** still opens it.

```
┌──────────────────────────────────────────────────────────┐
│  █▀▄ █ █ █▄ █   the sanctuary                            │
│  █▀▄ █ █ █ ▀█                                            │
│  ▀ ▀ ▀▀▀ ▀  ▀                                            │
├──────────────────────────────────────────────────────────┤
│ [ run ] filter                                           │
├──────────────────────────────────────────────────────────┤
│ █ Blender               3D modeler                       │
│ ░ Bluetooth Manager                                      │
│ ░ Brave Web Browser     Web Browser                      │
│ ░ btop++                System Monitor                   │
└──────────────────────────────────────────────────────────┘
```

**Two processes, and only one of them is resident.** walker 2.x is a GTK4 + layer-shell front end
with no data of its own; **elephant** is the provider service that knows about desktop entries.
Without elephant, walker opens and sits on "Waiting for elephant...". elephant runs as a systemd
*user* service via `services.elephant.enable` in `/etc/nixos/services.nix`, bound to
`graphical-session.target` so it starts and dies with the session. walker itself has **no startup
entry and no pre-warmed instance** — a cold walker is on screen in ~80ms measured, which is
fuzzel's own order of magnitude, so there is nothing to keep warm.

elephant auto-detects the compositor and launches through it — the log line is
`runprefix autodetect="niri msg action spawn --"`. Nothing had to be configured for that.

| Element | Spec | Real characters? |
|---|---|---|
| **Gutter** | `█` current row / `░` every other, down the left edge — the bar's workspace language turned on its side. | **Yes** — see the overlay trick below |
| **Banner** | 3-line block `RUN` in lavender with `the sanctuary` beside it. | **Yes** |
| **Prompt** | `[ run ]` in lavender, `filter` ghost text. Carried over from `fuzzel.ini` verbatim. | **Yes** |
| **Empty state** | `— nothing —`, set from `[placeholders]` in `config.toml`. The house form of nothing, matching swaync's `— nothing waiting —`. | **Yes** |
| **Rows** | Name capped at 22 chars, `GenericName` beside it in `overlay0`. An entry with no GenericName renders no subtitle — walker's own `subtext_transformer` calls `set_visible(false)` on an empty one, so §2's empty-states-render-nothing comes free. | n/a |
| **Selection** | A filled `surface0` row, not a coloured highlight — the block of fill is the indicator, same call `fuzzel.ini` made. | n/a |
| **Island** | crust fill, 1px `#8b92b8` border, radius 0, no shadow. Border tone carried over from `fuzzel.ini` so the surface keeps its identity across the swap. | **No — 1px CSS border** |
| **Icons** | Off. App icons are full-colour artwork that cannot be restyled (§7, same cause as the tray). | n/a |
| **Keybind hints / quick-activation** | Off. fuzzel printed no legend and neither does this. | n/a |

**Where the line is between real characters and rendered ones.** A `─` glyph in JetBrainsMono and
a 1px CSS border are the same line to the eye, and a border tracks the box width for free where a
run of `─` would have to be counted against a pixel width. So the hairlines are CSS and
**everything wider than a hairline is a character.** That is the whole compromise, and it is
smaller than it sounded before it was built.

#### The gutter: getting `█`/`░` back after calling it impossible

The known GTK wall is that CSS has no `content:` property, so a stylesheet cannot swap one
character for another — the same wall the swaync close button hit. Since which glyph a row shows
depends on whether the row is selected, and only CSS knows that, the bar's `█`/`░` pair looked
unreachable. **It is not.**

Ship *both* characters, stacked in a `GtkOverlay` so they occupy the same cell, and let CSS flip
their `opacity` on `child:selected`:

```xml
<object class="GtkOverlay" id="SanctuaryGutter">
  <child>              <object class="GtkLabel" id="SanctuaryGutterIdle">   ░ </object></child>
  <child type="overlay"><object class="GtkLabel" id="SanctuaryGutterActive"> █ </object></child>
</object>
```
```css
.gutter-idle { opacity: 1; }  .gutter-active { opacity: 0; }
child:selected .gutter-idle { opacity: 0; }  child:selected .gutter-active { opacity: 1; }
```

Both glyphs are genuinely drawn; one is just at zero alpha. Nothing is approximated with a
background tint. **This generalises: any state-dependent glyph in GTK can be done as a stack of
real characters cross-faded by opacity.** Worth remembering the next time `content:` is the
obvious answer and is missing.

#### Theming traps, all four verified the hard way

- **`item.xml` in a custom theme is NEVER READ.** walker's loader iterates a fixed filename list —
  `layout.xml`, `keybind.xml`, `style.scss`, `style.css`, `preview.xml` — plus one
  `item_<provider>.xml` per provider elephant reports. The generic `item.xml` name only exists
  inside walker's embedded default. The row template here is
  **`item_desktopapplications.xml`**, and adding a provider to `[providers]` means adding its
  `item_<provider>.xml` too or that provider falls back to walker's built-in two-line row. This
  cost a full debugging round: the theme loaded, the banner and colours applied, and the rows
  silently kept the default layout with no gutter.
- **A custom theme inherits the default.** `setup_theme_from_path` starts from `Theme::default()`
  and overwrites only the files present, so this theme is three files and not fifteen.
- **`-gtk-icon-size: 0px` floods the log.** GTK asserts `size > 0` internally
  (`gtk_icon_theme_lookup_by_gicon: assertion 'size > 0' failed`), once per row per keystroke.
  Use `1px` — invisible and legal. That took the GTK criticals from a flood to zero.
- **Cap the subtitle's `max-width-chars`.** GTK sizes a box from its children's natural width, so
  without a cap an entry like *"Equalizer, Compressor and Other Audio Effects"* widens the whole
  island and the launcher changes width with whatever matched.

Objects can safely be *omitted* from a custom layout — walker guards every lookup with
`if let Some(...)` — but hiding via CSS is still preferred, because a future walker version may
start requiring one.

#### What was lost coming from fuzzel, and it is permanent

**Matched characters are no longer highlighted.** fuzzel painted them mauve (`match=cba6f7ff`) and
the fzf launcher did the same. walker sets row text with `label.set_text()`; `set_markup` appears
nowhere outside its preview module, so there is no Pango markup on list rows and no way to colour
a substring. This is not a theming gap that can be configured around — it is absent from the
renderer. It is the one thing fuzzel did better, and the reason `fuzzel.ini` is still on disk.

Also gone: the live `apps / up / load` readout the terminal launcher had. walker reads `layout.xml`
once at startup, so the banner is static text. Printing a number that would be a lie five minutes
later is worse than not printing it, so the caption is the name instead.

#### The cost, measured

| | |
|---|---|
| open, cold, no resident walker | **~80 ms** (fuzzel ~20 ms, the fzf launcher ~400 ms) |
| resident walker | **none** |
| elephant, as shipped here (2 providers) | **48 MB RSS — 11 MB anonymous** |
| elephant, nixpkgs default (25 providers) | 369 MB RSS — 122 MB anonymous |
| elephant startup | 61 ms, 57 desktop files indexed |

**elephant's default build enables all 25 providers and that is not acceptable here.** Several are
for other distros entirely and do nothing but log an error and switch themselves off
(`pacman: executable file not found`, `apt-cache command not found`). Note which number matters:
most of the 369 MB is `RssFile` — mapped `.so` and shared-library pages, shared and reclaimable.
The figure representing real pressure is the anonymous one, and **122 MB is roughly what the
warm-kitty launcher was rejected for.** Trimmed, it is 11 MB, which is not worth arguing about.

So `/etc/nixos/services.nix` pins a trimmed build:

```nix
services.elephant.package = pkgs.elephant.override {
  enabledProviders = [ "desktopapplications" "calc" ];
};
```

**`calc` is in that list to dodge a nixpkgs bug, not because the launcher needs it.** The package's
`postInstall` is:

```
wrapProgram $out/bin/elephant \
  --prefix PATH : ${lib.makeBinPath runtimeDeps} \
  --set ELEPHANT_PROVIDER_DIR "$out/lib/elephant/providers"
```

`runtimeDeps` is empty unless one of `files` / `bluetooth` / `calc` / `clipboard` is enabled. With
it empty that middle line becomes `--prefix PATH : ` , which consumes the following flag, and the
build dies at the very end with **`makeWrapper doesn't understand the arg
ELEPHANT_PROVIDER_DIR`** — after compiling successfully, which makes it read like a compile
problem when it is an argument-quoting one. `calc` pulls `libqalculate` and keeps `runtimeDeps`
non-empty. Any `enabledProviders` list excluding all four hits this. Worth reporting upstream.

`[providers]` in `config.toml` is separately held to `desktopapplications` alone — the same
decision `fuzzel.ini` made with `list-executables-in-path=no`, for the same stated reason: a
diluted fuzzy match means the launcher "stopped being one keypress". calc is built but not
queried; adding it to the query set is one word.

Adding a provider is three edits, not one: `enabledProviders` in `services.nix`, `[providers]` in
`config.toml`, and an `item_<provider>.xml` in the theme or it renders as walker's default
two-line row. elephant also ships `clipboard`, `files`, `websearch`, `symbols`, `unicode`, `todo`,
`playerctl`, `niriactions`, `nirisessions` and `windows` — `windows` in particular is an alt-tab
replacement sitting there unused.

### Clipboard picker (cliphist + fzf) — BUILT · clear-all added 2026-09-22

`scripts/sanctuary/clipboard.sh`. **Mod+V.** A floating kitty (`sanctuary-clipboard`) running
`cliphist list` through fzf. This one stays a terminal on purpose — clipboard history *is* text,
so a TUI is not a costume here, it is the honest shape. Contrast §3, where the launcher was not.

```
┌ clipboard ────────────────────────────────────────────────────┐
│ [ paste ]                                            555/555 │
│ ───────────────────────────────────────────────────────────── │
│ ▌ [ clear all ]                                               │
│ ▸ 1952    [1/19/32 built, 45 copied (277.7 MiB)] building n·· │
│ ▌ 1951    Mod+R {spawn-sh "noctalia msg config-reload";}      │
└───────────────────────────────────────────────────────────────┘
```

| Element | Spec |
|---|---|
| **Clear all** | A real selectable row, `[ clear all ]`, pinned at the top. Selecting it runs `cliphist wipe`. |
| **Delete one** | `Ctrl+X` on any row — deletes that entry and reloads in place. |
| **Movement** | `Ctrl+J` / `Ctrl+K`, house style. |

**Why clear-all is a row and not only a keybind.** Same reasoning §1 gives for the notification
centre's `[ clear all ]` button: an affordance you cannot see is one you cannot press. Harry asked
for it directly — *"a text entry in the clipboard menu to clear the clipboard items."*

**`--bind 'load:down'`, not `start:down`.** The clear row sits at the top, so the cursor has to
begin one row below it or the default Enter wipes 555 entries instead of pasting the newest one.
The `start` event fires *before* the item list exists, so the cursor move was silently discarded
and the pointer sat on `[ clear all ]` at open — verified by rendering it. `load` fires once the
list is in, and also re-fires after a `Ctrl+X` reload, which is the behaviour you want anyway.

**No confirmation prompt, deliberately.** `cliphist wipe` is not reversible, but §1 says nothing
regularly touched may require navigating, and clipboard history rebuilds itself within a day.
Being one row out of the default cursor position is the whole safety margin.

**The rows are not ANSI-coloured, deliberately.** Colouring `[ clear all ]` would mean passing
`--ansi` to fzf, and every other row here is arbitrary text off the internet. Letting fzf
interpret escape sequences in copied content mangles the list at best. The brackets carry the
affordance instead — which is the house language anyway.

### Modes — BUILT · 2026-09-25

`scripts/sanctuary/mode.sh` + `scripts/sanctuary/modes/*.conf`. **Mod+Shift+Z** opens the picker:
fzf in a floating kitty (`sanctuary-mode`), same idiom as the clipboard and the mixer.

**A mode is a file.** `modes/<name>.conf` is shell key/value — gaps, struts, radius, opacity,
which bar, blur, DND. Adding a mode is adding a file; the picker lists whatever is in that
directory, sorted by `ORDER`. The keybind never changes.

| | What it is |
|---|---|
| **Default** | The Sanctuary as designed. Square, tight, full ASCII bar, notifications on. |
| **Zen** | 16px gaps, 40px struts, 12px window radius, a lone window centred, clock pill only, DND on. |
| **Zen — no bar** | Zen with no bar at all. `Mod+Shift+A` still peeks the pill back in. |

**Why a rendered file and not a "zen override" include.** niri permits exactly **one** top-level
`layout {}` block — a second one fails validation with *"duplicate node `layout`, single node
expected"*. So a mode cannot add gaps on top of the base layout; it has to **be** the layout
block. `mode.sh` renders `niri/templates/mode.kdl.in` into `niri/mode.kdl` with that mode's
numbers and calls `niri msg action load-config-file`.

Shape is the opposite case and worth knowing: **`window-rule` blocks are additive and the last one
wins.** That is the only reason a mode can override the 2px radius floor in `window-rules.kdl` —
`config.kdl` includes `mode.kdl` *after* it. Reorder those two includes and the radius silently
stops applying, with no error anywhere.

The install is reversible: the outgoing `mode.kdl` is kept, the *composed* config is run through
`niri validate`, and a failure puts the old file back and says so in a critical toast. A bad mode
file cannot leave the desktop with a broken config.

**Three traps hit building it**, all fixed, all likely to recur:

- **SIGHUP.** The picker runs inside a kitty that exits the instant you choose, so everything it
  starts dies with it — the same trap that made the fsel launcher look broken. `bar.sh` now
  `setsid`s waybar, and `mode.sh pick` `setsid`s the apply.
- **strftime eats pango percentages.** `<span size='90%'>` inside a waybar clock format renders the
  module *empty*: the whole string is a strftime spec and `%'` is not a valid conversion. Keyword
  sizes (`smaller`) have no `%` and survive. An empty module looks exactly like a CSS bug.
- **Bar blur is a rectangle, and it is per-mode.** A `layer-rule` matching `waybar` blurs the layer's
  whole *surface rectangle* — every pixel of it, painted or not — so two things follow. It has to be
  per-mode (`mode.sh` emits it only for `BAR_BLUR=yes`), because the full bar is opaque islands with
  transparent air between them and a global rule smears a strip across the screen. And the zen bar's
  surface has to be **exactly** the size of the pill (`width: 200` in its config, `min-width: 160` +
  `20px` padding + `min-height: 34` in its CSS), or the leftover surface blurs as a pale halo around
  it. A layer-rule's `geometry-corner-radius` does **not** round that rectangle — tested at 0 and 17
  on niri 26.04, pixel-identical output — which is why the pill's radius is a modest 12px (matching
  zen's windows): the blur's square corners overshoot by ~3px of soft gradient and disappear. At 17,
  a true pill, they read as four pale nubs.

**The zen clock is the one surface that is not TUI-native.** Dark sheer pill (mantle at 0.55,
blurred behind), flamingo time, overlay0 date, fully rounded, soft drop shadow. Reasoning in §2:
zen holds one thing, and a frame around one thing is decoration. `waybar/zen/{config.jsonc,style.css}`.

### Windows (niri) — BUILT

`geometry-corner-radius` is **2** in Default and **12** in Zen. Layout no longer lives in
`layout.kdl` at all — that file became `niri/templates/mode.kdl.in`, rendered per mode (see Modes
above). Borders stay mocha lavender focused / `overlay0`
unfocused — and they finally *hold*, because `noctalia.kdl` (which silently
overwrote them with pink `#f5c2e7`) is gone.

### Wallpaper picker — BUILT

`scripts/sanctuary/wallpaper.sh`, bound to **Mod+Shift+W**. Floating kitty running `yazi` over
`~/Pictures/Wallpapers` — kitty's graphics protocol gives real previews, `hjkl` + Enter applies
via `awww`. yazi runs in `--chooser-file` mode, so Enter writes the selection and exits and the
script keeps control to do the applying and remember it in
`~/.local/state/sanctuary/wallpaper`. `wallpaper.sh restore` re-applies at startup.

The wallpaper fade is **0.4s**, the one deliberate exception to the 160ms rule — nothing is
waiting on it, so a longer fade reads as calm rather than sluggish.

**Upstream renamed `swww` to `awww` at 0.12.** The nixpkgs `swww` attribute is now an alias, so
the package installs but the binaries are `awww` / `awww-daemon`. This looked exactly like "the
rebuild silently skipped swww" for a while. The script and the niri layer-rule accept both names.

### Lock — BUILT · SDDM (SilentSDDM) — NOT BUILT

`scripts/sanctuary/lock.sh` — swaylock-effects, Mocha ring, JetBrainsMono, blurred screenshot,
0.16s fade in.

**The chain matters more than the flags.** `Mod+Escape` calls `loginctl lock-session`, which
emits logind's Lock signal; `swayidle`'s `lock` handler runs the locker. Idle-lock (10 min) and
suspend-lock go through the same handler, so there is exactly one locker and one look, not three
code paths. `swayidle` lives in `scripts/sanctuary/idle.sh` rather than inline in `startup.kdl`,
because **KDL strings take no backslash line-continuations** and the whole chain would otherwise
be one unreadable line.

**NixOS gotcha:** swaylock has no PAM stack of its own — without
`security.pam.services.swaylock = { }` it accepts your password and then refuses to unlock.
That is now set in `/etc/nixos/security.nix`.

**If Mod+Escape does nothing, swayidle is not running.** `loginctl lock-session` exits 0 whether
or not anything is listening — logind just emits the signal. swayidle only starts from
`startup.kdl`, i.e. at session start, so after editing that file the bind stays dead until you
log out and back in (or run `scripts/sanctuary/idle.sh` by hand). Check with `pgrep -x swayidle`
— and note `pgrep -f swayidle` will match your own shell and lie to you.

SilentSDDM is already a flake input but is not configured. That is the remaining half.

### Night light (wl-gammarelay-rs) — BUILT

`scripts/sanctuary/nightlight.sh`. **Manual, always on, never scheduled.**

- **Mod+Ctrl+Minus** warmer · **Mod+Ctrl+Equal** cooler · **Mod+Ctrl+0** off (6500K)
- 300K per press, clamped 1500–6500K. 6500K is neutral daylight — above it the screen is
  blue-shifted, which is the opposite of a night light.
- The last value is written to `~/.local/state/sanctuary/nightlight` and restored at startup.

**Why not wlsunset.** wlsunset is a *scheduler*: it interpolates between two temperatures across
sunrise and sunset and exposes no way to say "warmer, now". It was the right pick while the
requirement was "automatic"; the requirement changed to manual, and it has no IPC at all.
`wl-gammarelay-rs` is a daemon that just holds a temperature behind a DBus property, which is
exactly the manual case. `gammastep` was rejected for the same reason as wlsunset, plus geoclue.

Since the bar has no night-light module, **the notification is the readout** — a block meter
`[ night ░░░███ ]` plus the Kelvin value, on a fixed replaces-id so repeated presses update one
toast instead of stacking a column of them.
---

## 6. Open — next session

Harry's words: *"i'd need some more tweaks and some more ascii-designs. i really like the ascii
workspace indicator."*

The block-glyph workspace indicator is the strongest element built so far. Extend that language:

- ~~**Volume** as a block meter~~ — done, `[ vol ████░░░ ]`. **Brightness skipped: no
  `/sys/class/backlight` device on this machine.** It is a desktop; there is nothing to dim.
- ~~**Music position** as a block meter~~ — done 2026-09-25, `▓▓▓░░░░░` in the music island
- ~~**Islands as drawn frames** (corner ticks instead of a full accent outline)~~ — done 2026-09-25
- **Battery / capacity** bars in the same idiom (desktop, so low priority)
- **A floating player TUI** on the music module's right-click — `rmpc` in a `sanctuary-music`
  window. The niri window-rule is already written and waiting; only the bind is missing.
- ~~**Box-drawing separators**~~ — done, one `│` between the audio and system clusters
- ~~**Braille** in the bar~~ — in as of 2026-09-25: the workspace indicator is braille cells.
  Read the font trap in §5 before adding any more of it.
- **Workspace density**: a variant that sizes each cell by how many windows the workspace holds
  (`⠄ ⠆ ⠶ ⠿ ⣿`, event-driven off `niri msg -j event-stream`) was built and left unbound in
  `runs/2026-09-25_waybar-ascii-redesign/output/`. It turns the indicator into a readout — which
  desktops have work waiting — if the plain strip ever feels too quiet.
- **CPU/RAM** as braille sparklines (`⣀⣄⣆⣇⣿`) if a system module is ever wanted. Deliberately
  not built: it adds a polling process, and §1 of `DESKTOP-PLAN.md` says every process has to
  earn its RAM on an i5-6500.
- ~~**Notification count** as block glyphs~~ — done, `▁ ▃ ▅ ▇ █`
- ~~**The launcher** in the same idiom~~ — done, and it is the biggest surface running the `█`/`░`
  pair: walker's gutter marks the current row `█` and every other row `░`, cross-faded by
  opacity. See §5 — the technique generalises to any state-dependent glyph in GTK.
- A **`fastfetch`/`kotofetch` dashboard** on a keybind, same visual language
- **A window switcher.** elephant already ships a `windows` provider, and `niriactions` /
  `nirisessions` besides. An alt-tab in the launcher's own language is one provider away — one
  word in `[providers]`, one word in `enabledProviders`, and an `item_windows.xml`. Nothing to
  build from scratch. See §5's trap list before writing that item template.

Also open: whether the bar gets a name from `NAMING-CONVENTION.md`.

---

## 7. Unsolved

**The tray.** System tray icons are full-colour app artwork and cannot be restyled — they are
the loudest, least controlled thing on the bar. GTK3's `-gtk-icon-effect: dim` only applies to
passive items. Options: accept it, drop the tray for a `fuzzel`/TUI tray menu on a keybind, or
find a desaturation approach that works in waybar's GTK3. Harry wants the tray visible, so this
is not simply "delete it."

---

## 8. Checklist before shipping any component

- [ ] Is it an island — bordered, filled, square?
- [ ] Does its border colour identify it without reading the content?
- [ ] Do empty states render *nothing*, not a greyed placeholder?
- [ ] Does every action have a keybind?
- [ ] ASCII/block glyphs preferred over icon-font symbols?
- [ ] Any colour outside Mocha? Any second font? Any radius above 2px?
- [ ] Does any regular action require opening something and then navigating?
- [ ] Legible at a glance by someone exhausted?
