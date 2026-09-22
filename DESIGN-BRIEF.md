# The Sanctuary — Design Brief

Reference for anyone (human or agent) designing or building components for this desktop.
Read this **before** writing any config, CSS, or theme file.

Companion to `DESKTOP-PLAN.md` (what we're building, in what order). This file is
**how it should look and behave**.

**Status:** direction settled. Bar, launcher, notifications, wallpaper, lock and night light built.
noctalia removed from every config. SDDM theming unstarted.
**Updated:** 2026-09-22

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

### Rules

| Axis | Rule |
|---|---|
| **Structure** | Islands, not transparency. Every module is a bordered box with a fill. Visible structure *is* the craft. |
| **Shape** | 0–2px radius. Square. No exceptions. |
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

---

## 5. Component specs

### Bar (waybar) — BUILT

`~/.dotfiles/waybar/{config.jsonc,style.css}`. Variants A and B kept in `variants/` for
reference.

```
┌─────────┐                    ┌──────────────┐          ┌───────────────────┐ ┌────────────┐   ┌───────┐ ┌─────┐
│ ░  █  ░ │                    │[ 15:08 Tue 22]│          │ ▶ KAWAI YUTO — …  │ │ [ mic on ] │ │ │ tray  │ │ [▃] │
└─────────┘                    └──────────────┘          └───────────────────┘ └────────────┘   └───────┘ └─────┘
   mauve                            peach                       lavender            green      sep neutral  peach
```

The clock sits **centre**: it is the one module read without being looked for.
Everything actionable is right, where the pointer already is, and the
notification block is dead last so it never moves when something else changes
width.

| Module | Spec |
|---|---|
| **Workspaces** | `█` active / `░` inactive / `▓` urgent, mauve border. **The favourite element — ASCII blocks. Keep this language and extend it elsewhere.** |
| **Clock** | `[ 15:08  Tue 22 ]`, peach, **centred**. |
| **Music** | `▶` / `‖` + artist — title, 42ch truncation, lavender. Dims when paused. Click toggles playback, scroll skips. Right-click is deliberately unbound — a floating player TUI is the eventual answer, not a popup. |
| **Mic** | `[ mic on ]` green / `[ mic -- ]` neutral. A readout first: **right-click** cuts the mic, **left-click** opens `wiremix` as a floating terminal. `Mod+M` is the real interface. |
| **Separator** | `│` in `surface1`, no fill, no border. Splits the right side into an audio cluster and a system cluster. |
| **Tray** | Neutral border. **Unsolved — see §7.** |
| **Notifications** | Rising block by queue depth — `▁ ▃ ▅ ▇ █` for 1/2/3/4/5+, peach, far right. Click toggles the centre, right-click toggles DND. Renders nothing when empty. |
| **Volume** | **Off the bar since 2026-09-22.** `scripts/volume.sh` still works and the `[ vol ████░░░ ]` meter is intact if it is ever wanted back; volume now lives on the keybinds and in `wiremix`. |

**NixOS gotcha:** the binary is wrapped — `pkill -x waybar` matches nothing. Use
`pkill -x .waybar-wrapped`. Stacked invisible instances caused a long debug detour once already.
**This applies to every wrapped binary here**, and it cuts both ways: `pgrep -x noctalia` also
returns nothing while noctalia is very much running as `.noctalia-wrapp`. Match on the full path
(`pgrep -f /run/current-system/sw/bin/noctalia`) before concluding something is dead.

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

### Launcher (fuzzel) — BUILT

`~/.dotfiles/fuzzel/fuzzel/fuzzel.ini`. Bound to **Mod+Space**.

**This reverses the earlier "do not use fuzzel" ruling.** The original objection was that
layer-shell surfaces are not animated by niri, so the launcher would pop in while real windows
slide. Harry chose fuzzel anyway on 2026-09-22; the animation gap is acceptable at this size.
If it starts to grate, niri 26.04's `layer-rule` is the place to look before reopening the
terminal-launcher option.

Styled as one island in the bar's language: crust fill, 1px muted-lavender border, radius 0,
JetBrainsMono, `[ run ]` prompt, **no icons** (app icons are full-colour artwork and cannot be
restyled — the tray problem in §7, same cause). Selection is a filled `surface0` row rather than
a coloured highlight: the block of fill is the indicator, same idea as `█` in the workspace
module.

`list-executables-in-path` is **off**. On it, the list ran past 1400 entries and the fuzzy match
diluted badly — the launcher stopped being one keypress. Desktop entries only (~44).

**Matching is tuned, not default.** `match-mode=fzf` with `fields=name,generic,keywords`;
`comment` and `categories` are left out on purpose because they match far too loosely and push
the thing you meant down the list. `show-actions=yes` surfaces desktop-entry actions ("new
window", "preferences"). Font is 13px rather than the bar's 12 — the bar is glanced at, this is
read while tired, and it is the one surface where a point of extra size costs nothing.

### Windows (niri) — BUILT

`geometry-corner-radius` is now **2**. Borders stay mocha lavender focused / `overlay0`
unfocused from `layout.kdl` — and they finally *hold*, because `noctalia.kdl` (which silently
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
- **Battery / capacity** bars in the same idiom (desktop, so low priority)
- **A floating player TUI** on the music module's right-click — `rmpc` in a `sanctuary-music`
  window. The niri window-rule is already written and waiting; only the bind is missing.
- ~~**Box-drawing separators**~~ — done, one `│` between the audio and system clusters
- **CPU/RAM** as braille sparklines (`⣀⣄⣆⣇⣿`) if a system module is ever wanted. Deliberately
  not built: it adds a polling process, and §1 of `DESKTOP-PLAN.md` says every process has to
  earn its RAM on an i5-6500.
- ~~**Notification count** as block glyphs~~ — done, `▁ ▃ ▅ ▇ █`
- A **`fastfetch`/`kotofetch` dashboard** on a keybind, same visual language

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
