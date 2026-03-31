return {
	"tris203/precognition.nvim",
	event = "VeryLazy",
	config = function()
		require("precognition").setup({
			startVisible = false,
		})
		vim.keymap.set("n", "<leader>h", function()
			require("precognition").toggle()
		end, { desc = "Toggle motion hints" })
	end,
}
