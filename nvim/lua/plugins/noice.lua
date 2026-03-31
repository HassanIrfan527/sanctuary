return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("noice").setup({
			cmdline = {
				enabled = true,
				view = "cmdline_popup",
				format = {
					cmdline = { pattern = "^:", icon = ":", lang = "vim" },
					search_down = { kind = "search", pattern = "^/", icon = "/", lang = "regex" },
					search_up = { kind = "search", pattern = "^%?", icon = "?", lang = "regex" },
					filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
					lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "lua", lang = "lua" },
					help = { pattern = "^:%s*he?l?p?%s+", icon = "?" },
				},
			},
			routes = {
				{ filter = { event = "msg_show", kind = "", find = "written" }, opts = { skip = true } },
				{ filter = { event = "msg_show", kind = "", find = "more line" }, opts = { skip = true } },
				{ filter = { event = "msg_show", kind = "", find = "fewer line" }, opts = { skip = true } },
				{ filter = { event = "msg_show", kind = "", find = "Already at" }, opts = { skip = true } },
			},
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},
			presets = {
				bottom_search = false,
				command_palette = true,
				long_message_to_split = true,
				inc_rename = false,
				lsp_doc_border = true,
			},
		})
	end,
}
