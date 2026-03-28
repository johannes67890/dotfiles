return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = function()
		local dashboard = require("custom.dashboard")
		local uv = vim.uv or vim.loop

		local function dotfiles_picker()
			require("telescope.builtin").find_files({
				cwd = dashboard.dotfiles_root(),
				hidden = true,
				follow = true,
			})
		end

		local function stats_section()
			local size = dashboard.stats_card_size()
			return {
				pane = 1,
				padding = 1,
				render = function(self, pos)
					local buf = vim.api.nvim_create_buf(false, true)
					local win
					local timer = assert(uv.new_timer())
					local col = pos[2] + math.floor((self.opts.width - size.width) / 2)

					local function render_card()
						if not vim.api.nvim_buf_is_valid(buf) then
							return
						end
						vim.bo[buf].modifiable = true
						vim.api.nvim_buf_set_lines(buf, 0, -1, false, dashboard.stats_card_lines())
						vim.bo[buf].modifiable = false
					end

					win = vim.api.nvim_open_win(buf, false, {
						relative = "win",
						win = self.win,
						row = pos[1] - 1,
						col = col,
						width = size.width,
						height = size.height,
						style = "minimal",
						border = "none",
						focusable = false,
						noautocmd = true,
					})
					vim.wo[win].wrap = false
					vim.wo[win].winhighlight = "Normal:SnacksDashboardNormal,NormalFloat:SnacksDashboardNormal"
					render_card()

					timer:start(1000, 1000, vim.schedule_wrap(render_card))

					local close = vim.schedule_wrap(function()
						if timer and not timer:is_closing() then
							timer:stop()
							timer:close()
						end
						pcall(vim.api.nvim_win_close, win, true)
						pcall(vim.api.nvim_buf_delete, buf, { force = true })
					end)

					self.on("UpdatePre", close, self.augroup)
					self.on("Closed", close, self.augroup)
				end,
				text = ("\n"):rep(size.height - 1),
			}
		end

		return {
			dashboard = {
				enabled = true,
				preset = {
					header = dashboard.header(),
					keys = {
						{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
						{ icon = " ", key = "f", desc = "Find File", action = function() require("telescope.builtin").find_files() end },
						{ icon = " ", key = "g", desc = "Find Text", action = function() require("telescope.builtin").live_grep() end },
						{ icon = " ", key = "r", desc = "Recent Files", action = function() require("telescope.builtin").oldfiles() end },
						{ icon = " ", key = "c", desc = "Dotfiles", action = dotfiles_picker },
						{ icon = "󰒲 ", key = "p", desc = "Plugins", action = ":Lazy" },
						{ icon = " ", key = "l", desc = "Lazygit", action = ":LazyGit" },
						{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
					},
				},
				sections = {
					{ section = "header", pane = 1 },
					stats_section,
					{ section = "startup", pane = 1, padding = 1 },
					{ section = "keys", pane = 2, gap = 1, padding = 1 },
					{
						pane = 2,
						icon = " ",
						title = "Recent Files",
						section = "recent_files",
						indent = 2,
						padding = 1,
						limit = 5,
					},
					{
						pane = 2,
						icon = " ",
						title = "Projects",
						section = "projects",
						indent = 2,
						padding = 1,
						limit = 5,
					},
					function()
						return {
							pane = 2,
							icon = " ",
							title = dashboard.git_status_title(),
							section = "terminal",
							enabled = dashboard.in_git_repo,
							cmd = "git --no-pager diff --stat -B -M -C && git status --short --renames",
							height = 5,
							padding = 1,
							indent = 2,
							ttl = 300,
						}
					end,
				},
			},
			styles = {
				dashboard = {
					border = "rounded",
					width = 0.86,
					height = 0.86,
				},
				terminal = {
					border = "rounded",
				},
			},
		}
	end,
}
