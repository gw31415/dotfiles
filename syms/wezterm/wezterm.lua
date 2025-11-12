local wezterm = require 'wezterm';

local config = wezterm.config_builder()
local function toggle_blur(window)
	local overrides = window:get_config_overrides() or {}
	if not overrides.macos_window_background_blur then
		overrides.macos_window_background_blur = 0
	else
		overrides.macos_window_background_blur = nil
	end
	window:set_config_overrides(overrides)
end

wezterm.on('toggle-blur', toggle_blur)
wezterm.on('gui-attached', function()
	if wezterm.target_triple:find 'apple' then
		os.execute [[osascript -e "tell application \"System Events\" to key code 102"]]
	end
end)

config.color_scheme = 'Tomorrow Night'
config.default_prog = { 'sh', '-c', '$HOME/.nix-profile/bin/fish' }
config.hide_tab_bar_if_only_one_tab = true
config.font = wezterm.font_with_fallback { 'HackGen Console NF' }
config.font_size = 13
config.initial_cols = 150
config.initial_rows = 45
config.front_end = 'WebGpu'
---@diagnostic disable-next-line: assign-type-mismatch
config.macos_forward_to_ime_modifier_mask = 'SHIFT|CTRL'
config.window_background_opacity = 0.8
config.macos_window_background_blur = 20
---@diagnostic disable-next-line: inject-field
config.show_close_tab_button_in_tabs = false
config.tab_bar_at_bottom = true
config.show_new_tab_button_in_tab_bar = false
config.window_frame = {
	font = wezterm.font {
		family = 'HackGen Console NF',
		style = 'Italic',
	},
	font_size = 14,
	inactive_titlebar_fg = 'transparent',
	inactive_titlebar_bg = 'transparent',
	active_titlebar_fg = 'transparent',
	active_titlebar_bg = 'transparent',
	border_left_width = 0,
	border_right_width = 0,
	border_bottom_height = 0,
	border_top_height = 0,
}
config.window_background_gradient = {
	colors = { '#000000c5' },
}
config.colors = {
	tab_bar = {
		inactive_tab_edge = 'none',
	},
}
wezterm.on('format-tab-title', function(tab, _tabs, _panes, _config, _hover, max_width)
	local bg = 'none'
	local fg = 'white'
	if tab.is_active then
		bg = '#e5e5e5'
		fg = 'black'
	end
	local title = ' ' .. wezterm.truncate_right(
		wezterm.nerdfonts
		[tab.tab_index < 9 and ('md_numeric_' .. tab.tab_index + 1 .. '_box') or 'md_pound_box'] ..
		' ' .. tab.active_pane.title,
		max_width - 1
	) .. ' '

	local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider
	local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider
	return {
		{ Background = { Color = 'none' } },
		{ Foreground = { Color = bg } },
		{ Text = tab.is_active and SOLID_LEFT_ARROW or bg == 'none' and ' ' or SOLID_LEFT_ARROW },
		{ Background = { Color = bg } },
		{ Foreground = { Color = fg } },
		{ Text = title },
		{ Background = { Color = 'none' } },
		{ Foreground = { Color = bg } },
		{ Text = tab.is_active and SOLID_RIGHT_ARROW or bg == 'none' and ' ' or SOLID_RIGHT_ARROW },
	}
end)

config.keys = {
	{
		key = ']',
		mods = 'SUPER',
		action = wezterm.action {
			ActivateTabRelative = 1,
		},
	},
	{
		key = '[',
		mods = 'SUPER',
		action = wezterm.action {
			ActivateTabRelative = -1,
		},
	},
	{
		key = ']',
		mods = 'SUPER|SHIFT',
		action = wezterm.action {
			MoveTabRelative = 1,
		},
	},
	{
		key = '[',
		mods = 'SUPER|SHIFT',
		action = wezterm.action {
			MoveTabRelative = -1,
		},
	},
	{
		key = 's',
		mods = 'SUPER',
		action = wezterm.action {
			SplitHorizontal = {
				domain = 'CurrentPaneDomain',
			},
		},
	},
	{
		key = 's',
		mods = 'SUPER|SHIFT',
		action = wezterm.action {
			SplitVertical = {
				domain = 'CurrentPaneDomain',
			},
		},
	},
	{
		key = 's',
		mods = 'CTRL|SHIFT',
		action = wezterm.action.PaneSelect {
			alphabet = 'aoeuhtns'
		},
	},
	{
		key = 'h',
		mods = 'CTRL|SHIFT',
		action = wezterm.action.AdjustPaneSize {
			'Left', 3,
		},
	},
	{
		key = 'j',
		mods = 'CTRL|SHIFT',
		action = wezterm.action.AdjustPaneSize {
			'Down', 3,
		},
	},
	{
		key = 'k',
		mods = 'CTRL|SHIFT',
		action = wezterm.action.AdjustPaneSize {
			'Up', 3,
		},
	},
	{
		key = 'l',
		mods = 'CTRL|SHIFT',
		action = wezterm.action.AdjustPaneSize {
			'Right', 3,
		},
	},
	{
		key = 'w',
		mods = 'SUPER',
		action = wezterm.action {
			CloseCurrentPane = {
				confirm = true,
			},
		},
	},
	{
		key = 'b',
		mods = 'SUPER',
		action = wezterm.action { EmitEvent = 'toggle-blur' },
	},
	{
		key = ' ',
		mods = 'ALT',
		action = 'ToggleFullScreen'
	},
	{
		key = 'e',
		mods = 'SUPER',
		action = wezterm.action_callback(function(_window, pane)
			local target_pane_id = tostring(pane:pane_id())
			local env_path = string.format('%s/.nix-profile/bin:/opt/homebrew/bin:%s', os.getenv('HOME'),
				os.getenv('PATH'))
			pane:split {
				direction = "Bottom",
				set_environment_variables = {
					PATH = env_path,
				},
				args = {
					'pnpx',
					'editprompt',
					'--always-copy',
					'--editor',
					'nvim',
					'--mux',
					'wezterm',
					'--target-pane',
					target_pane_id,
				},
				size = 10,
			}
		end),
	}
}

return config
