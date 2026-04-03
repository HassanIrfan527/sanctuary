return {
	"folke/persistence.nvim",
	lazy = false,
	config = function()
		require("persistence").setup({
			need = 2,
			autostart = false,
		})

		vim.api.nvim_create_autocmd("VimEnter", {
			nested = true,
			callback = function()
				local args = vim.fn.argv()
				if #args > 0 then
					for _, arg in ipairs(args) do
						if arg:match("COMMIT_EDITMSG") or arg:match("MERGE_MSG") or arg:match("git%-rebase%-todo") then
							require("persistence").stop()
							return
						end
					end
					return
				end
				require("persistence").load()
			end,
		})

		vim.api.nvim_create_autocmd("BufReadPre", {
			once = true,
			callback = function()
				require("persistence").start()
			end,
		})
		vim.keymap.set("n", "<leader>qs", function() require("persistence").load() end, { desc = "Restore session" })
		vim.keymap.set("n", "<leader>ql", function() require("persistence").load({ last = true }) end, { desc = "Restore last session" })
		vim.keymap.set("n", "<leader>qd", function() require("persistence").stop() end, { desc = "Stop session tracking" })
	end,
}
