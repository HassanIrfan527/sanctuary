#!/usr/bin/env bash
# Our own Vencord build for Vesktop — it carries the SanctuaryComms userplugin
# (vesktop/sanctuaryComms: voice state → Quickshell's COMMS card, Mod+C).
#
#   vencord.sh build    copy the plugin into the checkout, install deps, build
#   vencord.sh update   git pull the checkout, then build      (run by hand)
#   vencord.sh where    print the dist dir to give Vesktop
#
# One-time: Vesktop → Settings → Vesktop Settings → Vencord Location → pick
# the dir `where` prints, restart Vesktop, then enable SanctuaryComms in
# Vencord → Plugins. A custom build means Vesktop no longer updates Vencord by
# itself: `update` is how it updates (when Discord breaks something, or monthly).
set -euo pipefail

SRC="${VENCORD_SRC:-$HOME/.local/src/Vencord}"
PLUGIN="$HOME/.dotfiles/vesktop/sanctuaryComms"

# pnpm without a global install: npx runs the exact version Vencord's
# package.json pins, from the npm cache. (Fedora's node has no corepack.)
pnpm() {
  if type -P pnpm >/dev/null; then command pnpm "$@"
  else npx --yes "$(node -p "require('$SRC/package.json').packageManager")" "$@"; fi
}

build() {
  [ -d "$SRC/.git" ] || git clone --depth 1 https://github.com/Vendicated/Vencord.git "$SRC"
  mkdir -p "$SRC/src/userplugins"
  rm -rf "$SRC/src/userplugins/sanctuaryComms"
  cp -r "$PLUGIN" "$SRC/src/userplugins/sanctuaryComms"
  cd "$SRC"
  pnpm install --frozen-lockfile
  pnpm build
  # Vesktop counts a Vencord dir as valid only if package.json is in it too;
  # without it, it "repairs" the dir by downloading the official release over
  # our build — and SanctuaryComms vanishes.
  printf '{}' > dist/package.json
  printf '\nbuilt → %s/dist  (restart Vesktop to load it)\n' "$SRC"
}

case "${1:-}" in
  build)  build ;;
  update) git -C "$SRC" pull --ff-only && build ;;
  where)  printf '%s/dist\n' "$SRC" ;;
  *)      sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
