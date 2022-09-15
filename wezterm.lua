local wezterm = require 'wezterm';
return {
	color_scheme = "Tomorrow Night",
	default_prog = {"/usr/local/bin/fish", "-l"},
	hide_tab_bar_if_only_one_tab = true,
	font = wezterm.font("HackGenNerd Console"),
	font_size = 13,
	initial_cols = 140,
	initial_rows = 45,
}
