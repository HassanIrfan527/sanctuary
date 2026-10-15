#!/usr/bin/env bash
# Mango's session plumbing — the job `niri-session` does for niri.
#
# SDDM starts Mango as plain `mango` (mango.desktop: Exec=mango), with no
# wrapper. So nobody tells systemd a graphical session began, and everything
# waiting on graphical-session.target never starts: /etc/xdg/autostart apps
# (polkit agent, gnome-keyring, nm-applet) and user services.
#
#   start  (exec_once at login)
#     1. copy Mango's environment into systemd + D-Bus, so services started
#        from now on know which display to draw on
#     2. start mango-session.target — it BindsTo graphical-session.target,
#        which pulls everything else in
#   stop   (power.sh, before quitting Mango)
#     stop the target, so the next login — Mango or niri — starts clean
set -uo pipefail

VARS=(WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP
      MANGO_INSTANCE_SIGNATURE XCURSOR_THEME XCURSOR_SIZE QT_QPA_PLATFORM)

case "${1:-start}" in
  start)
    systemctl --user reset-failed
    dbus-update-activation-environment --systemd "${VARS[@]}"
    systemctl --user start mango-session.target
    ;;
  stop)
    systemctl --user stop mango-session.target
    systemctl --user unset-environment "${VARS[@]}"
    ;;
esac
