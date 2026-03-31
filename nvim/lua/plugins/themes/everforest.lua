return {
	"neanias/everforest-nvim",
	name = "everforest",
	lazy = false,
	config = function()
		require("everforest").setup({})
	end,
}
