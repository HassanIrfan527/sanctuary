return {
	"catppuccin/nvim",
	name = "catppuccin",
	lazy = true,
	config = function()
		require("catppuccin").setup({
			flavour = "mocha",
			transparent_background = false,
			term_colors = true,
			dim_inactive = {
				enabled = false,
			},
			styles = {
				comments = { "italic" },
				conditionals = { "italic" },
				loops = {},
				functions = {},
				keywords = {},
				strings = {},
				variables = {},
				numbers = {},
				booleans = {},
				properties = {},
				types = {},
				operators = {},
			},
            integrations = {
            nvim_web_devicons = true,
            neo_tree = true,
            }
		})
	end,
}
