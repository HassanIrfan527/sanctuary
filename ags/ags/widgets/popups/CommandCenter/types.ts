export type Mode = "APPS" | "CMD" | "CLIP" | "HELP"

export interface Result {
  id: string
  title: string
  subtitle?: string
  icon?: string      // icon-name (gtk icon theme) or unicode glyph
  keyhint?: string   // shown on the right of the row
  section?: string   // section header above this row; grouped in list
  activate: () => void | Promise<void>
  score?: number
}

export interface Provider {
  mode: Mode
  // query excludes the prefix character (e.g. for "/ foo" you get "foo")
  query: (q: string) => Promise<Result[]> | Result[]
}
