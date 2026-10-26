return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = function()
		local dashboard = require("custom.dashboard")
		local uv = vim.uv or vim.loop
		local stats_ns = vim.api.nvim_create_namespace("custom_dashboard_stats")

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
					local timer = assert(uv.new_timer())
					local start_row = pos[1] - 1
					local end_row = start_row + size.height
					local start_col = pos[2]
					local pane_width = self.opts.width

					local function render_card()
						if not vim.api.nvim_buf_is_valid(self.buf) then
							return
						end
						local lines = dashboard.stats_card_virtual_lines(pane_width)
						vim.api.nvim_buf_clear_namespace(self.buf, stats_ns, start_row, end_row)
						for i, chunks in ipairs(lines) do
							vim.api.nvim_buf_set_extmark(self.buf, stats_ns, start_row + i - 1, start_col, {
								virt_text = chunks,
								virt_text_pos = "overlay",
								hl_mode = "combine",
							})
						end
					end

					vim.schedule(render_card)

					timer:start(1000, 1000, vim.schedule_wrap(render_card))

					local close = vim.schedule_wrap(function()
						if timer and not timer:is_closing() then
							timer:stop()
							timer:close()
						end
						if vim.api.nvim_buf_is_valid(self.buf) then
							vim.api.nvim_buf_clear_namespace(self.buf, stats_ns, start_row, end_row)
						end
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
					function()
						return {
							pane = 1,
							text = dashboard.header_text(),
							align = "center",
							padding = 2,
						}
					end,
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
						if not dashboard.in_git_repo() then
							return nil
						end
						local items = dashboard.git_status_items()
						for _, item in ipairs(items) do
							item.pane = 2
						end
						return vim.list_extend({
							{
								pane = 2,
								icon = " ",
								title = dashboard.git_status_title(),
							},
						}, items)
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
