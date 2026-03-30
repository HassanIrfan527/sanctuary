return {
	"folke/snacks.nvim",
	lazy = false,
	priority = 900,
	config = function()
		require("snacks").setup({
			dashboard = {
				enabled = true,
				sections = {
					{ section = "header" },
					{ section = "keys", gap = 1, padding = 1 },
					{ section = "recent_files", limit = 5, padding = 1 },
					{ section = "startup" },
				},
			},
			notifier = {
				enabled = true,
				timeout = 3000,
			},
			words = {
				enabled = true,
			},
		})
	end,
}
