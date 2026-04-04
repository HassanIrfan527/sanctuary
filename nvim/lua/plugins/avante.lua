return {
	"yetone/avante.nvim",
	lazy = true,
	version = false,
	build = "make",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"stevearc/dressing.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"nvim-tree/nvim-web-devicons",
		"zbirenbaum/copilot.lua",
	},
	keys = {
		{ "<leader>aa", "<cmd>AvanteToggle<CR>", desc = "Toggle Avante sidebar" },
		{ "<leader>ac", "<cmd>AvanteChat<CR>", desc = "Avante chat" },
		{ "<leader>ae", "<cmd>AvanteEdit<CR>", desc = "Avante edit", mode = { "n", "v" } },
	},
	config = function()
		require("avante").setup({
			provider = "copilot",
			behaviour = {
				auto_suggestions = false,
				auto_set_keymaps = true,
			},
			windows = {
				width = 35,
				sidebar_header = {
					rounded = true,
				},
			},
		})
	end,
}
