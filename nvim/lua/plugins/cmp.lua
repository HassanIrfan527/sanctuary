return {
	"hrsh7th/nvim-cmp",
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
		"rafamadriz/friendly-snippets",
	},
	config = function()
		local cmp = require("cmp")
		local luasnip = require("luasnip")

		require("luasnip.loaders.from_vscode").lazy_load()

		local enabled = false

		cmp.setup({
			enabled = function()
				return enabled
			end,
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},
			window = {
				completion = cmp.config.window.bordered({
					border = "rounded",
					winhighlight = "Normal:NormalFloat,CursorLine:PmenuSel,Search:None",
				}),
				documentation = cmp.config.window.bordered({
					border = "rounded",
					winhighlight = "Normal:NormalFloat",
				}),
			},
			formatting = {
				fields = { "abbr", "kind", "menu" },
				format = function(_, vim_item)
					local icons = {
						Text = "󰉿", Method = "󰆧", Function = "󰊕", Constructor = "",
						Field = "󰜢", Variable = "󰀫", Class = "󰠱", Interface = "",
						Module = "", Property = "󰜢", Unit = "󰑭", Value = "󰎠",
						Enum = "", Keyword = "󰌋", Snippet = "", Color = "󰏘",
						File = "󰈙", Reference = "󰈇", Folder = "󰉋", EnumMember = "",
						Constant = "󰏿", Struct = "󰙅", Event = "", Operator = "󰆕",
						TypeParameter = "",
					}
					vim_item.kind = string.format("%s %s", icons[vim_item.kind] or "", vim_item.kind)
					return vim_item
				end,
			},
			mapping = cmp.mapping.preset.insert({
				["<Tab>"] = cmp.mapping.select_next_item(),
				["<S-Tab>"] = cmp.mapping.select_prev_item(),
				["<CR>"] = cmp.mapping.confirm({ select = true }),
				["<Esc>"] = cmp.mapping.abort(),
			}),
			sources = cmp.config.sources({
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
			}, {
				{ name = "buffer" },
				{ name = "path" },
			}),
		})

		vim.keymap.set("n", "<leader>a", function()
			enabled = not enabled
			vim.notify("Autocomplete: " .. (enabled and "ON" or "OFF"))
		end, { desc = "Toggle autocomplete" })
	end,
}
