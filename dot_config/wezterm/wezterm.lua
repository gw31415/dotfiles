local wezterm = require "wezterm"

local function toggle_blur(window)
	local overrides = window:get_config_overrides() or {}
	if not overrides.macos_window_background_blur then
		overrides.macos_window_background_blur = 0
	else
		overrides.macos_window_background_blur = nil
	end
	window:set_config_overrides(overrides)
end

wezterm.on("toggle-blur", toggle_blur)

return {
	color_scheme = "Tomorrow Night",
	default_prog = { "/opt/homebrew/bin/fish", "-l" },
	hide_tab_bar_if_only_one_tab = true,
	font = wezterm.font "HackGen Console NF",
	font_size = 14,
	initial_cols = 180,
	initial_rows = 52,
	front_end = "WebGpu",
	macos_forward_to_ime_modifier_mask = "SHIFT|CTRL",
	window_background_opacity = 0.8,
	macos_window_background_blur = 20,
	keys = {
		{
			key = "]",
			mods = "SUPER",
			action = wezterm.action {
				ActivateTabRelative = 1,
			},
		},
		{
			key = "[",
			mods = "SUPER",
			action = wezterm.action {
				ActivateTabRelative = -1,
			},
		},
		{
			key = "]",
			mods = "SUPER|SHIFT",
			action = wezterm.action {
				MoveTabRelative = 1,
			},
		},
		{
			key = "[",
			mods = "SUPER|SHIFT",
			action = wezterm.action {
				MoveTabRelative = -1,
			},
		},
		{
			key = "s",
			mods = "SUPER",
			action = wezterm.action {
				SplitHorizontal = {
					domain = "CurrentPaneDomain",
				},
			},
		},
		{
			key = "s",
			mods = "SUPER|SHIFT",
			action = wezterm.action {
				SplitVertical = {
					domain = "CurrentPaneDomain",
				},
			},
		},
		{
			key = "s",
			mods = "CTRL|SHIFT",
			action = wezterm.action.PaneSelect {
				alphabet = "aoeuhtns"
			},
		},
		{
			key = "h",
			mods = "CTRL|SHIFT",
			action = wezterm.action.AdjustPaneSize {
				'Left', 3,
			},
		},
		{
			key = "j",
			mods = "CTRL|SHIFT",
			action = wezterm.action.AdjustPaneSize {
				'Down', 3,
			},
		},
		{
			key = "k",
			mods = "CTRL|SHIFT",
			action = wezterm.action.AdjustPaneSize {
				'Up', 3,
			},
		},
		{
			key = "l",
			mods = "CTRL|SHIFT",
			action = wezterm.action.AdjustPaneSize {
				'Right', 3,
			},
		},
		{
			key = "w",
			mods = "SUPER",
			action = wezterm.action {
				CloseCurrentPane = {
					confirm = true,
				},
			},
		},
		{
			key = "b",
			mods = "SUPER",
			action = wezterm.action { EmitEvent = "toggle-blur" },
		},
		{
			key = " ",
			mods = "ALT",
			action = wezterm.action.ToggleFullScreen,
		},
	},
}
