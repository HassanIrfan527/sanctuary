return {
	"yetone/avante.nvim",
	lazy = true,
	version = false,
	build = "make",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"nvim-tree/nvim-web-devicons",
		"zbirenbaum/copilot.lua",
	},
	keys = {
		{ "<leader>aa", "<cmd>AvanteToggle<CR>", desc = "Toggle Avante sidebar" },
		{ "<leader>ac", "<cmd>AvanteChat<CR>", desc = "Avante chat" },
		{ "<leader>ae", "<cmd>AvanteEdit<CR>", desc = "Avante edit", mode = { "n", "v" } },
		{ "<leader>af", "<cmd>AvanteToggleFocus<CR>", desc = "Focus Avante / Editor" },
	},
	config = function()
		require("avante").setup({
			provider = "copilot",
			behaviour = {
				auto_suggestions = false,
				auto_set_keymaps = true,
			},
			windows = {
				width = 40,
				sidebar_header = {
					rounded = true,
				},
				input = {
					prefix = "❯ ",
					height = 8,
				},
				ask = {
					floating = false,
					border = "rounded",
					start_insert = true,
				},
			},
			hints = { enabled = true },
		})
	end,
}
