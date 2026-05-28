# VOID — Suggestions / Roadmap

Personal notes on what to add, change, or clean up in this config.
Written 2026-04-30. Revisit post-exams (mid-May 2026).

---

## Current state (snapshot)

- 45 plugins, ~1065 lines of plugin lua, 224-line init.lua, ~196ms startup.
- Tier: polished daily-driver. Not yet "showcase tier" — gap is debugging, testing, navigation primitives, and AI redundancy.
- Stack served well: Laravel/PHP, Python/FastAPI, JS/TS/React, SQL (dadbod), Lua, Markdown.

---

## Priority 1 — High leverage, low effort

### 1. Drop AI plugin redundancy
Currently have **avante.nvim + copilot.lua + supermaven.nvim** — three competing AI completion engines. Friction, not power.

**Decision:** keep one chat/agent + one completion (or zero completion if ghost text is unwanted).

- Ghost text (Copilot/Supermaven) — disabled by default, toggled with a keymap. Don't auto-show.
- Chat / multi-file agent — keep **avante.nvim** (closest to "Cursor in nvim").
- Drop the unused two entirely.

Reason: avoids three plugins racing to suggest things, simplifies cmp source ordering, reduces startup time.

### 2. Add harpoon (v2)
**`ThePrimeagen/harpoon`** branch `harpoon2`.

- Pin 4 files, jump with `<C-h/j/k/l>` or `<leader>1..4`.
- Replaces Telescope-every-time for the 4 files cycled most in any project (e.g., model + controller + view + test).
- 5-minute install, lifelong return.

### 3. Add `:Lazy profile` discipline
- Run `:Lazy profile` once a month.
- Aim for sub-100ms startup (currently ~196ms).
- Easy wins: lazy-load AI plugin on `InsertEnter`, defer dadbod until `ft = "sql"`, defer laravel.nvim until `ft = "php,blade"`.

---

## Priority 2 — Debugging (the real upgrade)

Goal: replicate what Console Ninja gives in VSCode (inline runtime values), but properly through DAP.

### Plugins to add
- **`mfussenegger/nvim-dap`** — debug adapter protocol core.
- **`rcarriga/nvim-dap-ui`** — visual debug UI (variables, watches, call stack, breakpoints panel).
- **`theHamsta/nvim-dap-virtual-text`** — **closest equivalent to Console Ninja**; shows variable values inline next to lines during a debug session.
- **`jay-babu/mason-nvim-dap.nvim`** — auto-installs debug adapters via mason.
- **`nvim-neotest/nvim-nio`** — required peer dep for dap-ui.

### Adapters (per-language)
- PHP / Laravel: **`xdebug`** (configured via mason-nvim-dap → `php-debug-adapter`)
- Python / FastAPI: **`debugpy`** (mason → `debugpy`)
- JS / TS / React: **`vscode-js-debug`** (mason → `js-debug-adapter`) + **`mxsdev/nvim-dap-vscode-js`**

### Keymap convention to add
| Key | Action |
|-----|--------|
| `<F5>` | Continue / start |
| `<F10>` | Step over |
| `<F11>` | Step into |
| `<F12>` | Step out |
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Conditional breakpoint |
| `<leader>du` | Toggle dap-ui |
| `<leader>dr` | Open REPL |
| `<leader>dl` | Run last |

### Reference configs (battle-tested)
- LazyVim's `lang.<language>.dap` modules.
- ThePrimeagen's dotfiles.
- Read first, copy-paste second.

---

## Priority 3 — Testing (neotest)

### Plugins
- **`nvim-neotest/neotest`** core
- Per-language adapters:
  - **`olimorris/neotest-phpunit`** or **`V13Axel/neotest-pest`** for PHP
  - **`nvim-neotest/neotest-python`** for pytest
  - **`nvim-neotest/neotest-jest`** or **`marilari88/neotest-vitest`** for JS

### What it does
- Run nearest test (`<leader>tn`), file (`<leader>tf`), full suite (`<leader>ta`).
- Inline pass/fail signs in the gutter.
- Output panel for failures, jump to failing assertion line.
- Integrates with DAP — debug a single test.

### Why it matters
"Professional dev" workflow. Once tests are inline you actually run them. Otherwise they rot.

---

## Priority 4 — Navigation & motion polish

### `oil.nvim`
- Edit filesystem as a buffer. Rename / move / create by editing text + `:w`.
- Complements neo-tree (oil for editing, neo-tree for browsing).
- Replaces netrw entirely.

### `nvim-treesitter-textobjects`
- `daf` delete-a-function, `vif` visual-inside-function, `dac` delete-around-class.
- The motions that make flex-config users look fast.
- Already have treesitter — this is a `dependencies` add.

### `incline.nvim`
- Floating filename labels on each split window.
- Tiny polish, makes multi-split work readable at a glance.

---

## Priority 5 — Refactoring

- **`ThePrimeagen/refactoring.nvim`** — extract function, extract variable, inline variable.
- Goes beyond LSP rename. Real structural edits.

---

## Priority 6 — Snippets (only if used)

- **`L3MON4D3/LuaSnip`** is likely already pulled by cmp. Check.
- Create `~/.dotfiles/nvim/snippets/` with personal snippets:
  - `php.json` — Laravel boilerplate (controllers, requests, models, migrations, factories).
  - `python.json` — FastAPI boilerplate (route, pydantic model, async handler, dependency).
  - `typescriptreact.json` — React boilerplate (component scaffold, hook scaffold).
  - `lua.json` — nvim plugin scaffold.

Skip this unless you actually write the same boilerplate weekly.

---

## Priority 7 — Custom Telescope extensions

Optional polish that adds personality:

- **`nvim-telescope/telescope-undo.nvim`** — visual undo tree picker.
- **`nvim-telescope/telescope-project.nvim`** — quick switch between projects.
- **`debugloop/telescope-undo.nvim`** — alternative.
- **`rcarriga/nvim-notify`** + `:Telescope notify` — searchable notification history.

---

## Things to leave alone (already correct)

- Transparency autocmd (re-fires on `ColorScheme` + `VimEnter`) — solid.
- Tmux status auto-toggle — small but excellent detail.
- Theme switcher with multiple variants — keep.
- VOID dashboard branding (snacks dashboard) — identity, don't homogenize.
- Lualine + bufferline + breadcrumbs (winbar) — three different layers, all needed.
- Laravel + dadbod + emmet + autotag — stack-correct, not bloat.

---

## Cleanup candidates (audit later)

- `cellular-automaton.lua` — fun but used? If yes, keep. If no, delete.
- `triforce.lua` — same.
- `twilight.lua` + `zen-mode.lua` — overlap. Pick one.
- `precognition.lua` — useful only if still learning motions. If motions are internalized, drop.

---

## Discipline rules (for future-self)

1. **Don't add a plugin without deleting/reviewing one.** Plugin count stays bounded.
2. **No plugin survives 30 days unused.** Audit quarterly.
3. **Every keymap goes through which-key with a `desc`.** Discoverability over memorization.
4. **`:Lazy profile` once a month.** Sub-100ms is the target.
5. **Don't theme-hop weekly.** Pick one for a quarter, learn it.
6. **Personal config beats public dotfiles.** Don't copy en4 / LazyVim wholesale — translate, don't import.

---

## Useful `:checkhealth` checklist

Run periodically:

```
:checkhealth
:checkhealth lazy
:checkhealth mason
:checkhealth lsp
:checkhealth treesitter
:checkhealth telescope
:Lazy profile
```

Watch for:
- Treesitter parsers out of sync with TS version.
- LSP servers installed but not started (likely filetype gap).
- Missing system tools (e.g. `node` for some plugins, `ripgrep`/`fd` for telescope speed).

---

## Order of attack (post-exams)

1. AI plugin cleanup (1 hour).
2. harpoon (10 min).
3. DAP setup for ONE language first (Python via debugpy is easiest). Add PHP + JS after.
4. neotest with ONE adapter (Python again — same debugger backbone).
5. oil.nvim + treesitter-textobjects (30 min).
6. refactoring.nvim (15 min).
7. Snippets — only if writing similar code repeatedly.

Don't try to do all of this in one weekend. One priority per week is sustainable.
