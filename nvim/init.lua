-- ══════════════════════════════════════
-- Neovim UI Configuration
-- Transparency, clean UI, smooth experience
-- ══════════════════════════════════════

--  ── Initializing lazy.nvim and its plugins  ──
require("config.lazy")

-- ── Treesitter highlighting ──
vim.api.nvim_create_autocmd("FileType", {
	callback = function(args)
		pcall(vim.treesitter.start, args.buf)
	end,
})

-- ── Line numbers ──
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"

-- ── Folding ──
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

-- ── Cursor ──
vim.opt.cursorline = true
vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50"

-- ── Indentation ──
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- ── Search ──
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- ── Scroll ──
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.smoothscroll = true

-- ── Splits ──
vim.opt.splitbelow = true
vim.opt.splitright = true

-- ── UI chrome ──
vim.opt.showmode = false
vim.opt.showcmd = false
vim.opt.cmdheight = 1
vim.opt.laststatus = 3
vim.opt.fillchars = { eob = " ", vert = "│", horiz = "─", horizup = "┴", horizdown = "┬", vertleft = "┤", vertright = "├", verthoriz = "┼" }
vim.opt.list = true
vim.opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }

-- ── Performance ──
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.redrawtime = 1500
vim.opt.lazyredraw = false

-- ── Terminal true colors ──
vim.opt.termguicolors = true

-- ── Transparent background ──
-- Makes nvim background transparent so kitty/terminal blur shows through
vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
        local groups = {
            "Normal", "NormalNC", "NormalFloat",
            "SignColumn", "EndOfBuffer",
            "CursorLineNr", "LineNr",
            "StatusLine", "StatusLineNC",
            "TabLine", "TabLineFill",
            "WinSeparator", "VertSplit",
            "Pmenu", "PmenuThumb",
            "TelescopeNormal", "TelescopeBorder",
            "TelescopePromptNormal", "TelescopePromptBorder",
            "TelescopeResultsNormal", "TelescopeResultsBorder",
            "TelescopePreviewNormal", "TelescopePreviewBorder",
            "CmpPmenu", "CmpDoc",
        }
        for _, group in ipairs(groups) do
            vim.api.nvim_set_hl(0, group, { bg = "NONE" })
        end
        vim.api.nvim_set_hl(0, "CursorLine", { bg = "#1a1a2e" })
        vim.api.nvim_set_hl(0, "Visual", { bg = "#2a2a4e" })
        vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#2a2a4e", fg = "#c0caf5" })
        vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE", fg = "#565f89" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#2a2a3e" })
    end,
})

-- Apply transparency on startup
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        vim.cmd("doautocmd ColorScheme")
    end,
})

-- ── Floating window defaults ──
vim.o.winblend = 15
vim.o.pumblend = 15

-- ── Window title ──
vim.opt.title = true
vim.opt.titlestring = "%f - Neovim"

-- ── Mouse ──
vim.opt.mouse = "a"

-- ── Clipboard ──
vim.opt.clipboard = "unnamedplus"

-- ── Undo persistence ──
vim.opt.undofile = true

-- ── Disable netrw banner ──
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3

-- ── Diagnostics ──
vim.diagnostic.config({
    virtual_text = true,
    float = { border = "rounded" },
})
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })

-- ── Clear search highlight ──
vim.keymap.set("n", "<Esc>", ":nohlsearch<CR>", { silent = true })

-- ── Window navigation ──
vim.keymap.set("n", "<Tab>", "<C-w>w", { desc = "Cycle windows" })
vim.keymap.set("n", "<S-Tab>", "<C-w>W", { desc = "Cycle windows reverse" })

-- ── Move lines ──
vim.keymap.set("n", "<leader>j", ":m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<leader>k", ":m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("v", "<leader>j", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<leader>k", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- ── LSP keymaps ──
vim.keymap.set("n", "gr", function() require("telescope.builtin").lsp_references() end, { desc = "Go to references (telescope)" })
vim.keymap.set("n", "gd", function() require("telescope.builtin").lsp_definitions() end, { desc = "Go to definition (telescope)" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code actions" })

-- ── Splits ──
vim.keymap.set("n", "<leader>sv", ":vsplit<CR>", { desc = "Split vertical" })
vim.keymap.set("n", "<leader>sh", ":split<CR>", { desc = "Split horizontal" })
vim.keymap.set("n", "<leader>sc", ":close<CR>", { desc = "Close split" })
