return {
	"folke/todo-comments.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	cmd = { "TodoTelescope", "TodoQuickFix", "TodoLocList" },
	keys = {
		{ "<leader>ft", ":TodoTelescope<CR>", desc = "Find TODOs" },
	},
	config = function()
		require("todo-comments").setup({})
	end,
}
