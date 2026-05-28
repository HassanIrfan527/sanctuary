import AstalApps from "gi://AstalApps"
import { fzfRank } from "../fzf"
import type { Provider, Result } from "../types"

const apps = new AstalApps.Apps()

export const appsProvider: Provider = {
  mode: "APPS",
  query(q: string): Result[] {
    const list = apps.get_list()
    const ranked = fzfRank(q, list, (a) => a.name + " " + (a.description ?? ""), 30)
    return ranked.map(({ item }) => ({
      id: `app:${item.entry}`,
      title: item.name,
      subtitle: item.description || item.executable || "",
      icon: item.iconName || "application-x-executable",
      section: "APPLICATIONS",
      activate: () => {
        item.launch()
      },
    }))
  },
}
