return {
	"akinsho/toggleterm.nvim",
	version = "*",
	config = function()
		require("toggleterm").setup({
			size = 15,
			open_mapping = false,
			direction = "float",
			float_opts = {
				border = "rounded",
			},
			on_open = function()
				vim.b.snacks_scroll = false
				vim.b.snacks_animate = false
			end,
		})
		vim.keymap.set({ "n", "t" }, "<leader>t", "<cmd>ToggleTerm<CR>", { desc = "Toggle terminal" })
	end,
}
