# Sanctuary dotfiles — notes for agent sessions

- **Before adding or changing any desktop module, style or variant, read `DESIGN-SYSTEM.md`.**
  Modules are written once on the style kit; they never check which style is on, never
  hardcode colours or fonts, and stay inside the file budget in its quick start.
- `DESIGN-BRIEF.md` is how the desktop should feel (the usage profile comes first).
- Saved, unbuilt plans: `docs/styles/lantern-harvest.md` (the pixel style).
- Never launch a compositor (niri / mango / mmsg), even headless. Don't pop UI on Harry's
  screen to test; validate headlessly and let him check visually at the end.
- Commits: no Claude co-author trailer.
