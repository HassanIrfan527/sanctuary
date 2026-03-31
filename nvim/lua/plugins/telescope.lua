return {
	"nvim-telescope/telescope.nvim",
	version = "*",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"sharkdp/fd",
		"nvim-tree/nvim-web-devicons",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},
	config = function()
		local telescope = require("telescope")
		local builtin = require("telescope.builtin")

		telescope.setup({})
		telescope.load_extension("fzf")

		vim.keymap.set("n", "<leader>ff", function()
			builtin.find_files({ hidden = true })
		end, { desc = "Find files (hidden)" })
		vim.keymap.set("n", "<leader>fF", function()
			builtin.find_files({ hidden = false })
		end, { desc = "Find files (no hidden)" })
		vim.keymap.set("n", "<leader>fg", function()
			builtin.live_grep({ additional_args = { "--hidden" } })
		end, { desc = "Grep across files" })
		vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Open buffers" })
		vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
		vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
		vim.keymap.set("n", "<leader>fc", builtin.colorscheme, { desc = "Switch colorscheme" })
		vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Keymaps" })
		vim.keymap.set("n", "<leader>gc", builtin.git_commits, { desc = "Git commits" })
	end,
}
