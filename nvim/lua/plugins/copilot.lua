return {
	"zbirenbaum/copilot.lua",
	opts = {
		suggestion = {
			enabled = true,
			auto_trigger = true,
			keymap = {
				accept = "<C-l>",
				accept_word = false,
				accept_line = false,
				next = "<C-j>",
				prev = "<C-k>",
				dismiss = "<C-\\>",
			},
		},
	},
}
