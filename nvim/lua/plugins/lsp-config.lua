return {
	{
		"mason-org/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},

	{
		"mason-org/mason-lspconfig.nvim",
		opts = {},
		dependencies = {
			"neovim/nvim-lspconfig",
		},
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"pyright",
					"intelephense",
					"ts_ls",
					"cssls",
					"html",
					"jsonls",
					"marksman",
					"tailwindcss",
				},
				handlers = {
					function(server_name)
						require("lspconfig")[server_name].setup({})
					end,
					["intelephense"] = function()
						require("lspconfig").intelephense.setup({
							filetypes = { "php", "blade" },
						})
					end,
					["html"] = function()
						require("lspconfig").html.setup({
							filetypes = { "html", "blade" },
						})
					end,
					["tailwindcss"] = function()
						require("lspconfig").tailwindcss.setup({
							filetypes = { "html", "css", "blade", "php", "vue", "javascriptreact", "typescriptreact" },
						})
					end,
				},
			})
		end,
	},
}
