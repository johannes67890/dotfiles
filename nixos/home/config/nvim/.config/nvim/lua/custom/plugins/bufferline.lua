return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "VeryLazy",
	config = function(_, opts)
		require("bufferline").setup(opts)
		local function update_showtabline()
			local bufs = vim.fn.getbufinfo({ buflisted = 1 })
			vim.o.showtabline = #bufs > 0 and 2 or 0
		end
		vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter" }, {
			callback = update_showtabline,
		})
		update_showtabline()
	end,
	keys = {
		{ "<Tab>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
		{ "<S-Tab>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
		{
			"<leader>bd",
			function()
				local n = vim.api.nvim_get_current_buf()
				local bufs = vim.fn.getbufinfo({ buflisted = 1 })
				if #bufs > 1 then
					for _, buf in ipairs(bufs) do
						if buf.bufnr ~= n then
							vim.api.nvim_set_current_buf(buf.bufnr)
							break
						end
					end
				end
				vim.api.nvim_buf_delete(n, { force = false })
			end,
			desc = "Delete buffer",
		},
	},
	opts = {
		options = {
			close_command = function(n)
				local bufs = vim.fn.getbufinfo({ buflisted = 1 })
				if #bufs > 1 then
					for _, buf in ipairs(bufs) do
						if buf.bufnr ~= n then
							vim.api.nvim_set_current_buf(buf.bufnr)
							break
						end
					end
				end
				vim.api.nvim_buf_delete(n, { force = false })
			end,
			diagnostics = "nvim_lsp",
			indicator = {
				style = "underline",
			},
			offsets = {
				{
					filetype = "neo-tree",
					text = "File Explorer",
					highlight = "Directory",
					text_align = "left",
				},
			},
		},
		highlights = {
			error = {
				fg = { attribute = "fg", highlight = "DiagnosticError" },
			},
			error_selected = {
				fg = { attribute = "fg", highlight = "DiagnosticError" },
				underline = true,
				sp = "#4D4030",
			},
			error_visible = {
				fg = { attribute = "fg", highlight = "DiagnosticError" },
			},
			error_diagnostic = {
				fg = { attribute = "fg", highlight = "DiagnosticError" },
			},
			error_diagnostic_selected = {
				fg = { attribute = "fg", highlight = "DiagnosticError" },
				underline = true,
				sp = "#4D4030",
			},
			error_diagnostic_visible = {
				fg = { attribute = "fg", highlight = "DiagnosticError" },
			},
			buffer_selected = {
				underline = true,
				sp = "#4D4030",
			},
			indicator_selected = {
				underline = true,
				sp = "#4D4030",
			},
			separator_selected = {
				underline = true,
				sp = "#4D4030",
			},
			close_button_selected = {
				underline = true,
				sp = "#4D4030",
			},
			modified_selected = {
				underline = true,
				sp = "#4D4030",
			},
			numbers_selected = {
				underline = true,
				sp = "#4D4030",
			},
			diagnostic_selected = {
				underline = true,
				sp = "#4D4030",
			},
			pick_selected = {
				underline = true,
				sp = "#4D4030",
			},
			duplicate_selected = {
				underline = true,
				sp = "#4D4030",
			},
			hint_selected = {
				underline = true,
				sp = "#4D4030",
			},
			info_selected = {
				underline = true,
				sp = "#4D4030",
			},
			warning_selected = {
				underline = true,
				sp = "#4D4030",
			},
			hint_diagnostic_selected = {
				underline = true,
				sp = "#4D4030",
			},
			info_diagnostic_selected = {
				underline = true,
				sp = "#4D4030",
			},
			warning_diagnostic_selected = {
				underline = true,
				sp = "#4D4030",
			},
		},
	},
}
