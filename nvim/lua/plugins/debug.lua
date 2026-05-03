return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
			"theHamsta/nvim-dap-virtual-text",
			"jay-babu/mason-nvim-dap.nvim",
		},
		keys = {
			{ "<F5>", function() require("dap").continue() end, desc = "DAP continue / start" },
			{ "<F10>", function() require("dap").step_over() end, desc = "DAP step over" },
			{ "<F11>", function() require("dap").step_into() end, desc = "DAP step into" },
			{ "<F12>", function() require("dap").step_out() end, desc = "DAP step out" },
			{ "<leader>dp", function() require("dap").toggle_breakpoint() end, desc = "DAP toggle breakpoint" },
			{ "<leader>dP", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "DAP conditional breakpoint" },
			{ "<leader>dl", function() require("dap").set_breakpoint(nil, nil, vim.fn.input("Log: ")) end, desc = "DAP logpoint" },
			{ "<leader>dr", function() require("dap").repl.open() end, desc = "DAP open REPL" },
			{ "<leader>dL", function() require("dap").run_last() end, desc = "DAP run last" },
			{ "<leader>du", function() require("dapui").toggle() end, desc = "DAP toggle UI" },
			{ "<leader>dh", function() require("dap.ui.widgets").hover() end, desc = "DAP hover value", mode = { "n", "v" } },
			{ "<leader>dt", function() require("dap").terminate() end, desc = "DAP terminate" },
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			require("mason-nvim-dap").setup({
				ensure_installed = { "python" },
				automatic_installation = true,
				handlers = {},
			})

			dapui.setup()

			require("nvim-dap-virtual-text").setup({
				commented = true,
				virt_text_pos = "eol",
				all_frames = false,
			})

			dap.listeners.before.attach.dapui_config = function() dapui.open() end
			dap.listeners.before.launch.dapui_config = function() dapui.open() end
			dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
			dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

			vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", linehl = "", numhl = "" })
			vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
			vim.fn.sign_define("DapLogPoint", { text = "◉", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
			vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual", numhl = "" })

			require("dap.python")
		end,
	},
}
