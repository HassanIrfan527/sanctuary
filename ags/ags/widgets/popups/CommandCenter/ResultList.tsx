import type { Accessor } from "ags"
import { For, createComputed } from "ags"
import type { Result } from "./types"
import ResultRow from "./ResultRow"

type Props = {
  items: Accessor<Result[]>
  selected: Accessor<number>
  onClick: (i: number) => void
}

type FlatEntry =
  | { kind: "header"; label: string; key: string; rowIndex: -1 }
  | { kind: "row"; result: Result; key: string; rowIndex: number }

export default function ResultList({ items, selected, onClick }: Props) {
  const flat = createComputed((): FlatEntry[] => {
    const list = items()
    const out: FlatEntry[] = []
    let last = ""
    list.forEach((r, i) => {
      if (r.section && r.section !== last) {
        out.push({ kind: "header", label: r.section, key: `h:${r.section}`, rowIndex: -1 })
        last = r.section
      }
      out.push({ kind: "row", result: r, key: `row:${i}:${r.id}`, rowIndex: i })
    })
    return out
  })

  return (
    <scrolledwindow
      cssClasses={["cc-scroll"]}
      hscrollbarPolicy={2}
      vscrollbarPolicy={1}
      vexpand
    >
      <box orientation={1}>
        <For each={flat} id={(e) => e.key}>
          {(entry) =>
            entry.kind === "header" ? (
              <label
                cssClasses={["cc-section"]}
                label={entry.label}
                xalign={0}
              />
            ) : (
              <ResultRow
                result={entry.result}
                index={entry.rowIndex}
                selected={selected}
                onClick={onClick}
              />
            )
          }
        </For>
      </box>
    </scrolledwindow>
  )
}
