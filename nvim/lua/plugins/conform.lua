return {
	"stevearc/conform.nvim",
	config = function()
		require("conform").setup({
			formatters_by_ft = {
				python = { "black" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				json = { "prettier" },
				css = { "prettier" },
				html = { "prettier" },
				markdown = { "prettier" },
				yaml = { "prettier" },
				php = { "php_cs_fixer" },
				lua = { "stylua" },
				toml = { "taplo" },
				c = { "clang_format" },
				cpp = { "clang_format" },
				go = { "gofumpt" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				zsh = { "shfmt" },
			},
			format_on_save = {
				timeout_ms = 500,
				lsp_format = "fallback",
			},
		})

		vim.keymap.set("n", "<leader>i", function()
			require("conform").format({ async = true })
		end, { desc = "Format file" })
	end,
}
