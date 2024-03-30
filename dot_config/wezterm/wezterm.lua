local wezterm = require("wezterm")
return {
	color_scheme = "Tomorrow Night",
	default_prog = { "/opt/homebrew/bin/fish", "-l" },
	hide_tab_bar_if_only_one_tab = true,
	font = wezterm.font("HackGen Console NF"),
	font_size = 14,
	initial_cols = 180,
	initial_rows = 52,
	front_end = "WebGpu",
	macos_forward_to_ime_modifier_mask = "SHIFT|CTRL",
	window_background_opacity = 0.8,
	macos_window_background_blur = 20,
}
