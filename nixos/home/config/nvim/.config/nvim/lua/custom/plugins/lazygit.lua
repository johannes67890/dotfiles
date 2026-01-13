return {
	"kdheepak/lazygit.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		-- <leader>g → LazyGit
		vim.keymap.set("n", "<leader>g", "<cmd>LazyGit<CR>", { desc = "Open Lazygit" })
	end,
}
