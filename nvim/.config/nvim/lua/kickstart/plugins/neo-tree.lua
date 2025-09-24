-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim
return {
	"nvim-neo-tree/neo-tree.nvim",
	version = "*",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
	},
	lazy = false,
	keys = {
		{ "\\", ":Neotree reveal<CR>", desc = "NeoTree reveal", silent = true },
		{ "<leader>fr", ":Neotree reveal<CR>", desc = "NeoTree reveal current file", silent = true },
	},
	opts = {
		filesystem = {
			filtered_items = {
				hide_dotfiles = false, -- show hidden files
				hide_gitignored = false, -- optional, show .gitignored files too
			},
			follow_current_file = {
				enable = true,
				leave_dirs_open = false,
			},
			window = {
				mappings = {
					["\\"] = "close_window",
				},
			},
		},
		buffers = { follow_current_file = { enable = true } },
	},
}
