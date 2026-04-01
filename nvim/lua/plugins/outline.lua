return {
	"hedyhli/outline.nvim",
	cmd = { "Outline", "OutlineOpen" },
	keys = {
		{ "<leader>o", "<cmd>Outline<CR>", desc = "Toggle outline" },
	},
	config = function()
		require("outline").setup({
			outline_window = {
				position = "right",
				width = 25,
			},
			symbol_folding = {
				autofold_depth = 1,
			},
		})
	end,
}
