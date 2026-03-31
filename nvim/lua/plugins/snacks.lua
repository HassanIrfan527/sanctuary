return {
	"folke/snacks.nvim",
	lazy = false,
	priority = 900,
	config = function()
		require("snacks").setup({
			dashboard = {
				enabled = true,
				preset = {
					header = [[
██╗   ██╗ ██████╗ ██╗██████╗
██║   ██║██╔═══██╗██║██╔══██╗
██║   ██║██║   ██║██║██║  ██║
╚██╗ ██╔╝██║   ██║██║██║  ██║
 ╚████╔╝ ╚██████╔╝██║██████╔╝
  ╚═══╝   ╚═════╝ ╚═╝╚═════╝
      ⟡  n o  e s c a p e  ⟡]],
					keys = {
						{ icon = " ", key = "f", desc = "Find File", action = ":Telescope find_files" },
						{ icon = " ", key = "g", desc = "Find Text", action = ":Telescope live_grep" },
						{ icon = " ", key = "r", desc = "Recent Files", action = ":Telescope oldfiles" },
						{
							icon = " ",
							key = "c",
							desc = "Config",
							action = ":Telescope find_files cwd=" .. vim.fn.stdpath("config"),
						},
						{ icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
						{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
					},
				},
				sections = {
					{ section = "header" },
					{ section = "keys", gap = 1, padding = 1 },
					{
						icon = " ",
						title = "Recent Files",
						section = "recent_files",
						limit = 5,
						indent = 2,
						padding = 1,
					},
					{ section = "startup" },
				},
			},
			notifier = {
				enabled = true,
				timeout = 3000,
			},
			words = {
				enabled = true,
			},
			quickfile = {
				enabled = true,
			},
			statuscolumn = {
				enabled = true,
			},
			animate = {
				enabled = true,
			},
			scroll = {
				enabled = true,
			},
			input = {
				enabled = true,
			},
		})
	end,
}
