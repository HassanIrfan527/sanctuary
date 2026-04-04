return {
	"supermaven-inc/supermaven-nvim",
	event = "InsertEnter",
	config = function()
		require("supermaven-nvim").setup({
			keymaps = {
				accept_suggestion = "<C-y>",
				clear_suggestion = "<C-]>",
				accept_word = "<C-j>",
			},
			disable_inline_completion = true,
		})

		local enabled = false
		vim.keymap.set("n", "<leader>sm", function()
			enabled = not enabled
			if enabled then
				require("supermaven-nvim.api").start()
				vim.cmd("SupermavenToggle")
			else
				vim.cmd("SupermavenToggle")
			end
			vim.notify("Supermaven: " .. (enabled and "ON" or "OFF"))
		end, { desc = "Toggle Supermaven" })
	end,
}
