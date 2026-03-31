return {
	"folke/zen-mode.nvim",
	dependencies = { "folke/twilight.nvim" },
	keys = {
		{ "<leader>z", "<cmd>ZenMode<CR>", desc = "Zen mode" },
	},
	config = function()
		require("zen-mode").setup({
			window = {
				backdrop = 0.95,
				width = 100,
			},
			plugins = {
				twilight = { enabled = true },
				kitty = {
					enabled = true,
					font = "+2",
				},
			},
		})
	end,
}
