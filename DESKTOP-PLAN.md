# The Sanctuary — Desktop Plan

Planning document for replacing Noctalia with a self-owned desktop on NixOS + niri.

**Status:** step 1 not started. **Steps 2–6 done in config** — bar, notifications, launcher,
wallpaper, lock, idle, night light, and noctalia removed from every file. **Nothing is live until
`sudo nixos-rebuild switch` installs the five new packages and the session is restarted.**
**Started:** 2026-09-22 · **Updated:** 2026-09-22

---

## 1. Why

The current desktop works but isn't *mine* — it's Noctalia's. The goal isn't a prettier
desktop, it's an **owned** one: every piece understood, every piece replaceable, nothing
depending on a project whose direction I don't control.

Hard constraints:

- **No QuickShell, no AGS.** Both mean writing and maintaining a shell (QML / TypeScript).
  Not doing that right now. Config files, not code.
- **No forking Omarchy.** References welcome, borrowed structure fine. Copying the repo, no.
- **No bloat.** i5-6500 / Intel HD 530 / 15GB / one 1920x1080@60. Every process has to earn
  its RAM and its GPU time.
- **Keyboard-first.** From `README.md`: *"Everything should be controlled by keyboard, and
  the whole OS is vim."* That's still the rule.

The desktop should be a **resting place** — immersive, calm, something I want to be inside
rather than something I operate. Beautiful, but not *modern-flashy*. Restrained animation is
fine; glass-and-glow maximalism is not.

---

## 2. Design language

**Moved to `DESIGN-BRIEF.md`.** Read that before touching any config.

Short version: **TUI-native.** The bar is a row of terminal panels — square islands, 1px
coloured borders, ASCII/block glyphs, Catppuccin Mocha. The whole system already runs on TUIs
(yazi, btop, lazygit, nvim, tmux); the chrome should agree with it.

Two directions were built and rejected along the way — a transparent text bar and a warm
minimalist "Ember" palette. Both are documented in `DESIGN-BRIEF.md` §3 with the reasons, so
they don't get re-proposed. **Do not pitch minimal/transparent chrome again.**

## 3. Stack

| Layer | Tool | Status |
|---|---|---|
| Compositor | **niri** | keep |
| Bar | **waybar** | installed |
| Launcher | **fuzzel** | built, bound to Mod+D |
| Notifications + centre | **swaync** | built, inactive until noctalia releases the bus |
| Wallpaper | **swww** | built — `scripts/sanctuary/wallpaper.sh` |
| Lock | **swaylock-effects** | built — `scripts/sanctuary/lock.sh` |
| Idle | **swayidle** | built — `scripts/sanctuary/idle.sh` |
| Night light | **wl-gammarelay-rs** | built — manual, keybind-adjusted |
| Power menu | **TUI menu in a floating terminal** | **not built** |
| Clipboard | **cliphist + fzf** | built — `scripts/sanctuary/clipboard.sh`, Mod+V |
| Screenshots | **grim / slurp / swappy** | installed |
| Colors | Catppuccin Mocha, locked | no switcher |

**New packages: six** — `swww` (installs as **`awww`** since 0.12 — the nixpkgs name is now an
alias), `swaylock-effects`, `swayidle`, `wl-gammarelay-rs`, `wiremix`, `libnotify`. All added to `/etc/nixos/environment.nix`; `matugen`, `walker` and the `noctalia`
flake input are gone.

**On fuzzel — reversed 2026-09-22.** This plan previously ruled fuzzel out: it is a layer-shell
surface and niri does not animate those, so the launcher pops in while every real window slides.
Harry chose fuzzel anyway. The objection still stands technically; it just is not worth a
terminal round-trip for a list of 44 desktop entries. If the missing transition starts to grate,
look at niri 26.04's `layer-rule` before reopening the terminal-launcher option.

The terminal-picker idiom still applies to the **menus** — power menu, clipboard, wallpaper.
Those are real windows, animate like everything else, and inherit the kitty theme.

### On flexibility (the real tradeoff)

waybar and mako *are* less flexible than QuickShell. Being honest about where:

- **Chrome and readouts** — no meaningful gap. waybar custom modules run arbitrary scripts and
  emit JSON (text, tooltip, class, percentage); GTK CSS styling goes deep. mako exposes
  colors, fonts, padding, radius, borders, and per-app rules.
- **Interactive panels** — this is where the gap is real. Media player with album art, audio
  mixer with sliders, calendar, wifi picker, notification center. QuickShell wins outright.

**The resolution: don't build GUI panels at all.** For a keyboard-driven system the answer to
"I need an audio mixer" is a floating terminal running `wiremix`, not a mouse-driven popup.
That's *more* flexible than QuickShell, requires zero code, and is far more "the whole OS is
vim" than any panel would be.

| Need | Panel-free answer |
|---|---|
| Audio mixer | `wiremix` in a floating terminal — Mod+Alt+M, or left-click the bar's mic |
| Wifi | `impala` or `nmtui` |
| Bluetooth | `bluetui` |
| Calendar | `calcurse` |
| System monitor | `btop` (installed) |
| Music | `rmpc` / player TUI |

Each gets a keybind and a niri window-rule. That *is* the panel system.

---

## 4. Decisions locked

1. **Config home** — home-manager installs packages and defines services; tweakable configs
   (niri, waybar, kitty, mako) use `mkOutOfStoreSymlink` pointing at `~/.dotfiles`, so
   they stay hand-editable with instant feedback. Nix rollback for the system, zero friction
   for the look.
2. **Screen chrome** — thin, always-on top bar.
3. **Color engine** — **Catppuccin Mocha, single locked palette.** No matugen (generated
   palettes are muddy and unpredictable) and **no theme switcher for now** — Harry hasn't
   changed theme in three weeks and the switcher was mostly a machine for fiddling. The
   `themes/` structure in §5 stays as future scaffolding; it is not being built yet. matugen
   gets removed at step 6.
4. **Pace** — one component at a time. ~~Noctalia stays installed and running until nothing
   depends on it.~~ **Cut over 2026-09-22.** Its state was moved, not deleted, to
   `~/.local/share/sanctuary-pre-cutover-2026-09-22/` — `~/.config/{noctalia,noctalia-v4-backup,caelestia}`
   plus `~/.dotfiles/{matugen,theme-backups}`. `/etc/nixos/*.bak` holds the pre-edit nix files.

---

## 5. File layout

```
/etc/nixos/home/modules/desktop/
  default.nix        # imports, package list
  niri.nix           # out-of-store symlink → ~/.dotfiles/niri
  waybar.nix         # package + systemd user service + symlink
  notifications.nix  # mako
  wallpaper.nix      # swww + systemd user service
  lock.nix           # locker + swayidle
  # theme.nix        # future only — palette is locked, no switcher being built

~/.dotfiles/
  waybar/{config.jsonc,style.css,scripts/}
  niri/niri/*.kdl
  swaync/swaync/{config.json,style.css}   # notifications + centre
  mako/mako/config        # inactive fallback, kept if the centre is regretted
  fuzzel/fuzzel/fuzzel.ini
  scripts/            # launcher, power menu, clipboard, wallpaper pickers
  themes/             # FUTURE scaffolding only — not built yet (palette is locked)
```

### How theming works (if a switcher is ever built)

niri, kitty and waybar-CSS support `include` / `@import` — those could point at a
`themes/current/` symlink farm, making a switch a symlink swap plus a reload signal. mako has no
include mechanism, so its config would be *generated* from a theme fragment.

**Not being built.** The palette is locked to Catppuccin Mocha. Recorded here only so the option
stays open later.

---

## 6. Sequence

1. **Foundation** — restructure home-manager with `mkOutOfStoreSymlink`, bring niri's config
   under it. Nothing changes visually. Noctalia keeps running. Proves the plumbing before
   anything depends on it. *(~20 min, reversible, zero visual payoff.)*
2. **Bar** — ✅ **built and chosen.** Three variants were run side by side against Noctalia;
   Harry picked variant C (square islands, per-module accent borders, ASCII block workspace
   indicator). Live at `~/.dotfiles/waybar/{config.jsonc,style.css}`; A and B kept in
   `variants/` for reference. **Still to do:** more ASCII modules (see `DESIGN-BRIEF.md` §6),
   the tray problem (§7), and wiring it into home-manager at step 1.
3. **Notifications** — ✅ **swaync built** at `~/.dotfiles/swaync/swaync/{config.json,style.css}`,
   symlinked to `~/.config/swaync`; both files verified to load with no parse errors. Replaces
   mako, because Harry asked for a notification centre and mako cannot host one (see
   `DESIGN-BRIEF.md` §5). mako's config stays as the inactive fallback. **Not yet live:** noctalia
   owns `org.freedesktop.Notifications`. *(Only the switch is left.)*
4. **Launcher + menus** — ✅ **fuzzel built and bound to Mod+D.** Additive: noctalia keeps
   Mod+Space until step 6, so nothing can strand you. **Still to do:** power menu and clipboard
   scripts as floating-terminal pickers, then drop noctalia's launcher and move fuzzel to
   Mod+Space.
5. **Wallpaper, lock, idle** — swww, locker, swayidle.
6. **Remove Noctalia** — ✅ **done in config, 2026-09-22.** Not yet *live*: the running
   noctalia process survives until the session restarts, and the replacements cannot start until
   the packages exist.

   | Where | What changed |
   |---|---|
   | `flake.nix` | `noctalia` input and `./noctalia.nix` removed |
   | `noctalia.nix` | deleted |
   | `configuration.nix` | `noctalia.cachix.org` substituter + key removed |
   | `environment.nix` | `walker` and `matugen` out; swww, swaylock-effects, swayidle, wlsunset, wiremix, libnotify in |
   | `security.nix` | `pam.services.swaylock` added — swaylock cannot unlock without it |
   | `niri/config.kdl` | `include "noctalia.kdl"` gone; the `debug` block **kept**, swaync needs it too |
   | `niri/noctalia.kdl` | deleted — this was the pink-border override in §8 |
   | `niri/startup.kdl` | rewritten: waybar, swaync, awww+restore, night light, swayidle |
   | `niri/effects.kdl` | both `^noctalia-*` layer-rules gone |
   | `niri/window-rules.kdl` | noctalia rules gone; radius 20 → 2; swww on the overview backdrop; four `sanctuary-*` floating rules |
   | `niri/binds.kdl` | all 15 noctalia binds rehomed |
   | `~/.config` | noctalia/caelestia state archived; the dangling `waybar` symlink repointed at `~/.dotfiles/waybar` |

   **The cutover, in order:**
   1. `sudo nixos-rebuild switch` — nothing below works before this.
   2. Log out and back in (or restart niri). That kills noctalia and runs the new
      `startup.kdl`. A half-measure — `pkill -f /run/current-system/sw/bin/noctalia` then
      starting the pieces by hand — also works if you don't want to lose your windows.
   3. Check in this order: wallpaper appears (awww), bar appears, `Mod+Space` launches,
      `Mod+Shift+D` opens the centre, `Mod+Escape` locks and **unlocks**.

   **Editing `startup.kdl` does not restart what it spawns.** niri hot-reloads binds and rules,
   but the startup block only runs at session start. After changing it, either log out or start
   the new pieces by hand — this is why `Mod+Escape` looked broken when swayidle simply was not
   running yet.

7. **ASCII modules + polish pass** — extend the block-glyph language from the workspace
   indicator: block meters for volume/brightness, box-drawing separators, braille sparklines.
   See `DESIGN-BRIEF.md` §6. *(Was "build the theme switcher" — dropped, palette is locked.)*
8. **Polish** — scope blur to specific windows instead of the global catch-all, the inscription
   layer, a `fastfetch` dashboard on a keybind.

Steps 2–5 each end with a working desktop. Nothing before step 6 can strand me, because
Noctalia stays installed the whole time.

---

## 7. Open questions

Mostly settled. What's left:

- **A power menu** — the last noctalia bind with no replacement. `Mod+O` and `Mod+I` (control
  centre, settings) were dropped outright; a TUI power menu in a floating terminal is still owed.
- **The tray** — full-colour app icons are the loudest, least controllable thing on the bar.
  Accept, drop for a keybind menu, or find a desaturation route. Harry wants it visible, so
  "delete it" isn't automatically the answer. See `DESIGN-BRIEF.md` §7.
- **More ASCII modules** — block meters for volume/brightness, box-drawing separators, braille
  sparklines. The block-glyph workspace indicator is the favourite element so far and the
  language should extend from it. See `DESIGN-BRIEF.md` §6.
- **Font** — JetBrainsMono Nerd Font for now. Iosevka or Berkeley Mono would have more
  character for chrome. Not urgent.

**Settled:** palette is Catppuccin Mocha, locked, no switcher. Notifications are **swaync, not
mako** — reversed 2026-09-22 when Harry asked for a full centre; mako has no panel surface, so it
could not have delivered one. Launcher is **fuzzel** — see the reversal note in §3.

## 8. Known issues in the current config

- ~~**Palette conflict.**~~ **Resolved 2026-09-22** — `noctalia.kdl` is deleted, so `layout.kdl`'s
  mocha lavender borders finally hold.
- **Global blur cost.** `effects.kdl` runs `blur { passes 2; offset 3.0 }` applied via a
  catch-all window-rule, plus blur on the overview — on every window, always. Real cost on HD
  530. Scope it at step 8.
- **Split config ownership.** home-manager currently manages only git, tmux and GTK theming;
  everything visual lives as plain files in `~/.dotfiles`. Paying the NixOS tax without the
  NixOS benefit. Resolves at step 1.
- ~~**Shell-hopping residue.**~~ **Resolved 2026-09-22** — archived to
  `~/.local/share/sanctuary-pre-cutover-2026-09-22/`, not deleted. Delete that directory once the
  cutover has survived a few days.

---

## 9. Deferred — power-user tooling

Not part of the Noctalia replacement. Revisit after step 6, once the base desktop is owned.

- **Screen recording** — `gpu-screen-recorder` (installed), `wf-recorder`, OBS for heavy work
- **Audio** — `pavucontrol` (installed), `wiremix` / `pulsemixer` for TUI control, `easyeffects`
  (config already present)
- **Microphone** — `easyeffects` noise suppression, or `noise-suppression-for-voice`
- **Camera** — `cameractrls` for controls, `mpv /dev/video0` for preview
- **Also worth listing later** — OCR, colour picker, emoji picker, unit conversion, scratchpad
