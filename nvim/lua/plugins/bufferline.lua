return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("bufferline").setup({
			options = {
				mode = "buffers",
				separator_style = "slant",
				show_close_icon = false,
				show_buffer_close_icons = true,
				diagnostics = "nvim_lsp",
				offsets = {
					{
						filetype = "neo-tree",
						text = "Explorer",
						highlight = "Directory",
						separator = true,
					},
				},
			},
		})

		vim.keymap.set("n", "<leader>n", ":BufferLineCycleNext<CR>", { desc = "Next buffer" })
		vim.keymap.set("n", "<leader>p", ":BufferLineCyclePrev<CR>", { desc = "Prev buffer" })
		vim.keymap.set("n", "<leader>x", ":bd<CR>", { desc = "Close buffer" })
	end,
}
