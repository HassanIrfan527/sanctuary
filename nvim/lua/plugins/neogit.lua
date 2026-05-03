return {
	"NeogitOrg/neogit",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"sindrets/diffview.nvim",
		"nvim-telescope/telescope.nvim",
		"esmuellert/codediff.nvim",
	},
	cmd = "Neogit",
	keys = {
		{ "<leader>gg", "<cmd>Neogit<CR>", desc = "Neogit" },
		{ "<leader>gs", "<cmd>Neogit<CR>", desc = "Git status (Neogit)" },
		{ "<leader>gc", "<cmd>Neogit commit<CR>", desc = "Git commit" },
		{ "<leader>gp", "<cmd>Neogit push<CR>", desc = "Git push" },
		{ "<leader>gl", "<cmd>Neogit pull<CR>", desc = "Git pull" },
		{ "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Git diff view" },
	},
	config = function()
		require("neogit").setup({
			integrations = {
				telescope = true,
				diffview = true,
			},
		})
	end,
}
