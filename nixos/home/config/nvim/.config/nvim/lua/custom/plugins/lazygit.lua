return {
	"kdheepak/lazygit.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		local group = vim.api.nvim_create_augroup("CustomLazyGitTerminal", { clear = true })

		local function open_lazygit_tab()
			if vim.fn.executable("lazygit") ~= 1 then
				vim.notify("lazygit is not installed", vim.log.levels.ERROR)
				return
			end

			local previous_tab = vim.api.nvim_get_current_tabpage()
			vim.cmd("tabnew")

			local tab = vim.api.nvim_get_current_tabpage()
			local buf = vim.api.nvim_get_current_buf()

			vim.bo[buf].buflisted = false
			vim.bo[buf].filetype = "lazygit"
			vim.wo.number = false
			vim.wo.relativenumber = false
			vim.wo.signcolumn = "no"
			vim.wo.statuscolumn = ""
			vim.wo.foldcolumn = "0"
			vim.wo.cursorline = false
			vim.wo.winbar = ""

			vim.fn.termopen({ "lazygit" }, {
				on_exit = function()
					vim.schedule(function()
						if vim.api.nvim_tabpage_is_valid(tab) then
							vim.cmd.tabclose()
						end

						if vim.api.nvim_tabpage_is_valid(previous_tab) then
							vim.api.nvim_set_current_tabpage(previous_tab)
						end
					end)
				end,
			})

			vim.api.nvim_create_autocmd("TermEnter", {
				group = group,
				buffer = buf,
				once = true,
				callback = function()
					vim.cmd("startinsert")
				end,
			})

			vim.keymap.set("n", "q", "<cmd>tabclose<CR>", { buffer = buf, silent = true })
			vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n><cmd>tabclose<CR>]], { buffer = buf, silent = true })
			vim.cmd("startinsert")
		end

		vim.keymap.set("n", "<leader>g", open_lazygit_tab, { desc = "Open Lazygit" })
	end,
}
