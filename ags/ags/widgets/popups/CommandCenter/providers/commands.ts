import app from "ags/gtk4/app"
import { execAsync } from "ags/process"
import AstalNotifd from "gi://AstalNotifd"
import { fzfRank } from "../fzf"
import type { Provider, Result } from "../types"

interface Cmd {
  title: string
  subtitle: string
  icon: string
  keyhint?: string
  run: () => void
}

const COMMANDS: Cmd[] = [
  {
    title: "Reload AGS",
    subtitle: "Hot-reload the shell",
    icon: "view-refresh-symbolic",
    run: () => execAsync(["bash", "-c", "pkill -USR1 gjs 2>/dev/null; ags quit; ags run -c app.grid.ts &"]),
  },
  {
    title: "Toggle DND",
    subtitle: "Silence notifications",
    icon: "notifications-disabled-symbolic",
    run: () => {
      const n = AstalNotifd.get_default()
      n.dontDisturb = !n.dontDisturb
    },
  },
  {
    title: "Lock Session",
    subtitle: "Hyprlock",
    icon: "system-lock-screen-symbolic",
    run: () => execAsync(["hyprlock"]).catch(() => {}),
  },
  {
    title: "Power Menu",
    subtitle: "Coming soon",
    icon: "system-shutdown-symbolic",
    run: () => console.log("[CommandCenter] power menu stub"),
  },
]

export const commandsProvider: Provider = {
  mode: "CMD",
  query(q: string): Result[] {
    const ranked = fzfRank(q, COMMANDS, (c) => c.title + " " + c.subtitle, 20)
    return ranked.map(({ item }) => ({
      id: `cmd:${item.title}`,
      title: item.title,
      subtitle: item.subtitle,
      icon: item.icon,
      keyhint: item.keyhint,
      section: "COMMANDS",
      activate: item.run,
    }))
  },
}
