-- Toggle: open the working-tree diff, or close whatever Diffview tab is open.
local function toggle()
	if require("diffview.lib").get_current_view() then
		vim.cmd("DiffviewClose")
	else
		vim.cmd("DiffviewOpen")
	end
end

-- Diff the current branch against the repo's default branch (main, else master).
local function diff_default_branch()
	local base = vim.fn.systemlist("git rev-parse --verify --quiet main")[1] and "main" or "master"
	vim.cmd("DiffviewOpen " .. base .. "...HEAD")
end

return {
	"sindrets/diffview.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles", "DiffviewRefresh" },
	opts = {
		enhanced_diff_hl = true,
		view = {
			merge_tool = {
				layout = "diff3_mixed",
				disable_diagnostics = true,
			},
		},
		file_panel = {
			listing_style = "tree",
			win_config = { width = 32 },
		},
		keymaps = {
			view = {
				{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
			},
			file_panel = {
				{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
			},
			file_history_panel = {
				{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
			},
		},
	},
	keys = {
		{ "<leader>dd", toggle, desc = "[D]iffview toggle (working tree)" },
		{ "<leader>dc", "<cmd>DiffviewClose<cr>", desc = "[D]iffview [c]lose" },
		{ "<leader>ds", "<cmd>DiffviewOpen --cached<cr>", desc = "[D]iffview [s]taged changes" },
		{ "<leader>dm", diff_default_branch, desc = "[D]iff vs [m]ain/master" },
		{ "<leader>dp", "<cmd>DiffviewOpen HEAD~1<cr>", desc = "[D]iffview vs [p]revious commit" },
		{ "<leader>dh", "<cmd>DiffviewFileHistory<cr>", desc = "[D]iffview repo [h]istory" },
		{ "<leader>df", "<cmd>DiffviewFileHistory --follow %<cr>", desc = "[D]iffview [f]ile history" },
		{ "<leader>df", ":DiffviewFileHistory<cr>", mode = "v", desc = "[D]iffview selection history" },
		{ "<leader>dt", "<cmd>DiffviewToggleFiles<cr>", desc = "[D]iffview [t]oggle file panel" },
		{ "<leader>dr", "<cmd>DiffviewRefresh<cr>", desc = "[D]iffview [r]efresh" },
	},
}
