return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").setup({})

		vim.filetype.add({
			pattern = {
				[".*%.blade%.php"] = "blade",
			},
		})


		local parsers = { "lua", "python", "javascript", "typescript", "bash", "json", "css", "html", "markdown", "tsx", "toml", "go", "c", "cpp", "php", "blade" }
		local installed = require("nvim-treesitter").get_installed("parsers")
		local installed_set = {}
		for _, p in ipairs(installed) do installed_set[p] = true end
		for _, p in ipairs(parsers) do
			if not installed_set[p] then
				require("nvim-treesitter").install(p)
			end
		end
	end,
}
