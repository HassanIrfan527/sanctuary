return {
	"ellisonleao/gruvbox.nvim",
	name = "gruvbox",
	lazy = false,
	priority = 900,
	config = function()
		require("gruvbox").setup({
			terminal_colors = true,
			contrast = "", -- "" = warm cream #fbf1c7 (medium)
			transparent_mode = false,
			italic = {
				strings = false,
				comments = true,
				folds = false,
			},
		})
		-- NB: colorscheme is applied by init.lua based on the active
		-- variant (theme_active.lua), so we do NOT call it here.
	end,
}
