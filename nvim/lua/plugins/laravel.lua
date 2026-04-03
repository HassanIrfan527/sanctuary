local is_laravel = function()
	return vim.fn.filereadable("artisan") == 1
end

return {
	{
		"adalessa/laravel.nvim",
		cond = is_laravel,
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"tpope/vim-dotenv",
			"MunifTanjim/nui.nvim",
			"nvim-neotest/nvim-nio",
		},
		keys = {
			{ "<leader>la", function() require("laravel.commands.artisan").handle() end, desc = "Laravel artisan" },
			{ "<leader>lr", function() require("laravel.commands.routes").handle() end, desc = "Laravel routes" },
			{ "<leader>lm", function() require("laravel.commands.related").handle() end, desc = "Laravel related files" },
		},
		opts = {},
	},
	{
		"RicardoRamirezR/blade-nav.nvim",
		cond = is_laravel,
		ft = { "blade", "php" },
		opts = {},
	},
}
