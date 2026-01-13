return {
	{
		"Mofiqul/vscode.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.o.background = "dark"
			local c = require("vscode.colors").get_colors()
			require("vscode").setup({
				transparent = false,
				italic_comments = true,
				underline_links = true,
				disable_nvimtree_bg = true,
				color_overrides = {
					vscBack = "#1a1a1a", -- darker background
					vscLineNumber = "#5c6370", -- muted numbers
				},
				group_overrides = {
					Cursor = { fg = c.vscDarkBlue, bg = c.vscCursorDark, bold = true },
				},
			})

			vim.cmd.colorscheme("vscode")

			-- Muted indent guides
			vim.api.nvim_set_hl(0, "IndentBlanklineChar", { fg = "#3e4452" })
			vim.api.nvim_set_hl(0, "IndentBlanklineContextChar", { fg = "#4b5263" })
		end,
	},
}
