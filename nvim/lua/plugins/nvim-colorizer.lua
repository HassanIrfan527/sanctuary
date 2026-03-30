return {
	"norcalli/nvim-colorizer.lua",
	config = function()
		require("colorizer").setup({
			"*",
		}, {
			css = true,
			css_fn = true,
			mode = "background",
		})
	end,
}
