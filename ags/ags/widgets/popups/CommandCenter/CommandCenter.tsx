import app from "ags/gtk4/app"
import { createState, createComputed } from "ags"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import Corners from "../../ui/Corners"
import SearchRow from "./SearchRow"
import ResultList from "./ResultList"
import Footer from "./Footer"
import { appsProvider } from "./providers/apps"
import { commandsProvider } from "./providers/commands"
import { clipboardProvider } from "./providers/clipboard"
import type { Mode, Provider, Result } from "./types"

const WINDOW_NAME = "command-center"

function modeFor(q: string): Mode {
  if (q.startsWith("/")) return "CMD"
  if (q.startsWith(":")) return "CLIP"
  if (q.startsWith("?")) return "HELP"
  return "APPS"
}

function providerFor(mode: Mode): Provider {
  switch (mode) {
    case "CMD": return commandsProvider
    case "CLIP": return clipboardProvider
    case "HELP": return helpProvider
    default: return appsProvider
  }
}

function stripPrefix(q: string, mode: Mode): string {
  if (mode === "APPS") return q
  return q.slice(1).trimStart()
}

const helpProvider: Provider = {
  mode: "HELP",
  query: () => [
    {
      id: "help:soon",
      title: "Keybinds coming soon",
      subtitle: "The `?` module will live here",
      icon: "help-about-symbolic",
      section: "HELP",
      activate: () => {},
    },
  ],
}

export default function CommandCenter() {
  const [query, setQuery] = createState("")
  const [items, setItems] = createState<Result[]>([])
  const [selected, setSelected] = createState(0)

  const mode = createComputed(() => modeFor(query()))
  const count = createComputed(() => items().length)
  const entryRef: { current: Gtk.Entry | null } = { current: null }

  let gen = 0
  async function refresh(q: string) {
    const m = modeFor(q)
    const p = providerFor(m)
    const sub = stripPrefix(q, m)
    const myGen = ++gen
    const result = await p.query(sub)
    if (myGen !== gen) return
    setItems(result)
    setSelected(0)
  }

  function onChange(text: string) {
    setQuery(text)
    void refresh(text)
  }

  function activate() {
    const list = items.peek()
    const idx = selected.peek()
    const r = list[idx]
    if (!r) return
    try { void r.activate() } catch (e) { console.error(e) }
    app.get_window(WINDOW_NAME)?.set_visible(false)
  }

  function onKey(keyval: number, _state: number): boolean {
    const KEY_Up = Gdk.KEY_Up
    const KEY_Down = Gdk.KEY_Down
    const KEY_Escape = Gdk.KEY_Escape
    const KEY_k = Gdk.KEY_k
    const KEY_j = Gdk.KEY_j

    if (keyval === KEY_Escape) {
      app.get_window(WINDOW_NAME)?.set_visible(false)
      return true
    }
    if (keyval === KEY_Up || (keyval === KEY_k && (_state & Gdk.ModifierType.CONTROL_MASK))) {
      const len = items.peek().length
      if (len > 0) setSelected((s) => (s - 1 + len) % len)
      return true
    }
    if (keyval === KEY_Down || (keyval === KEY_j && (_state & Gdk.ModifierType.CONTROL_MASK))) {
      const len = items.peek().length
      if (len > 0) setSelected((s) => (s + 1) % len)
      return true
    }
    return false
  }

  // Initial populate with apps
  void refresh("")

  return (
    <window
      name={WINDOW_NAME}
      namespace={WINDOW_NAME}
      cssClasses={["grid", "CommandCenter"]}
      visible={false}
      application={app}
      keymode={Astal.Keymode.EXCLUSIVE}
      layer={Astal.Layer.OVERLAY}
      exclusivity={Astal.Exclusivity.IGNORE}
      anchor={0}
      onNotifyVisible={(self) => {
        if (self.visible) {
          setQuery("")
          void refresh("")
          entryRef.current?.set_text("")
          entryRef.current?.grab_focus()
        }
      }}
    >
      <box cssClasses={["cc-root"]}>
        <Corners>
          <box cssClasses={["cc-frame"]} orientation={1}>
            <SearchRow
              mode={mode}
              count={count}
              onChange={onChange}
              onActivate={activate}
              onKey={onKey}
              entryRef={entryRef}
            />
            <ResultList
              items={items}
              selected={selected}
              onClick={(i) => {
                setSelected(i)
                activate()
              }}
            />
            <Footer />
          </box>
        </Corners>
      </box>
    </window>
  )
}
