import { execAsync } from "ags/process"
import { fzfRank } from "../fzf"
import type { Provider, Result } from "../types"

// cliphist list output: "<id>\t<preview>" per line.
async function loadClip(): Promise<Array<{ id: string; preview: string }>> {
  try {
    const out = await execAsync(["bash", "-c", "cliphist list"])
    return out
      .split("\n")
      .filter(Boolean)
      .map((line) => {
        const tab = line.indexOf("\t")
        if (tab < 0) return { id: line, preview: line }
        return { id: line.slice(0, tab), preview: line.slice(tab + 1) }
      })
  } catch {
    return []
  }
}

export const clipboardProvider: Provider = {
  mode: "CLIP",
  async query(q: string): Promise<Result[]> {
    const entries = await loadClip()
    const ranked = fzfRank(q, entries, (e) => e.preview, 40)
    return ranked.map(({ item }) => ({
      id: `clip:${item.id}`,
      title: item.preview.slice(0, 80),
      subtitle: `#${item.id}`,
      icon: "edit-paste-symbolic",
      section: "CLIPBOARD",
      activate: async () => {
        await execAsync([
          "bash",
          "-c",
          `cliphist decode ${item.id} | wl-copy`,
        ])
      },
    }))
  },
}
