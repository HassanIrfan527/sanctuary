# gtk-dracula — retired 2026-10-12

What ~/.config/gtk-4.0 and gtk-3.0/settings.ini held before Flare v2:
- gtk-4.0/gtk.css — Dracula palette as libadwaita @define-color overrides
- gtk-4.0/{gtk-dark.css,libadwaita.css,libadwaita-tweaks.css,assets} — symlinks
  into /usr/share/themes/adw-gtk3/gtk-4.0 (forced adw-gtk3 onto libadwaita apps)
- gtk-3.0/settings.ini — gtk-theme-name=Dracula + prefer-dark=1

Replaced by stock Adwaita: GTK4 follows the system color-scheme, GTK3 gets
adw-gtk3 / adw-gtk3-dark (Adwaita look; GTK3 has no "Adwaita-dark") from scripts/sanctuary/shell.sh point_scheme.
Restore: copy gtk-4.0/* back to ~/.config/gtk-4.0 (cp -P keeps the links).
