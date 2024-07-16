{ pkgs, ... }:
let name = "ama"; in
{
  home.packages = with pkgs; [
    aria2
    asciinema
    bat
    carbon-now-cli
    chezmoi
    delta
    deno
    dotnet-sdk_7
    emacs
    eza
    ffmpeg
    flyctl
    fzf
    gh
    git-credential-manager
    go
    gopls
    hugo
    imagemagick
    jdupes
    jnv
    jq
    litecli
    mise
    mmv-go
    neovim
    nodejs
    pandoc
    poppler
    python3
    ripgrep
    rustup
    sccache
    silicon
    starship
    tectonic
    tmux
    typst
    wasmer
    wezterm
    wget
    yt-dlp
    zig
  ];

  home.file = {
    ".latexmkrc".source = ./.latexmkrc;
    ".emacs.d" = {
      source = ./.emacs.d;
      recursive = true;
    };
    ".config" = {
      source = ./.config;
      recursive = true;
    };
  };
  home.sessionVariables = {
    EDITOR = "nvim";
    RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
    SHELL = "${pkgs.fish}/bin/fish";
  };

  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    userName = "gw31415";
    extraConfig.credential.helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
    userEmail = "gw31415@amas.dev";
    delta.enable = true;
    ignores = [
      ".DS_Store"
      "kls_database.db"
      "flake.lock"
    ];
  };
  programs.wezterm = {
    enable = true;
    extraConfig = ''
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
      wezterm.on("gui-attached", function()
      	if wezterm.target_triple:find("apple") then
      		os.execute [[osascript -e "tell application \"System Events\" to key code 102"]]
      	end
      end)

      return {
      	color_scheme = "Tomorrow Night",
      	default_prog = { "${pkgs.fish}/bin/fish" },
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
    '';
  };
  programs.fish = {
    enable = true;
    plugins = [
      { name = "z"; src = pkgs.fishPlugins.z; }
      { name = "fzf"; src = pkgs.fishPlugins.fzf; }
      { name = "autopair"; src = pkgs.fishPlugins.autopair; }
    ];
    shellAbbrs = {
      tree = "eza -T";
    };
    shellInit = ''
      if test -f /opt/homebrew/bin/brew
        eval (/opt/homebrew/bin/brew shellenv)
      end
      starship init fish | source
      if status is-interactive
        mise activate fish | source
      else
        mise activate fish --shims | source
      end
      if test -d /Applications/Android\ Studio.app/Contents/jbr/Contents/Home
        export JAVA_HOME=/Applications/Android\ Studio.app/Contents/jbr/Contents/Home
      end
      source "$HOME/.cargo/env.fish"
    '';
  };
  manual.manpages.enable = true;
  home = {
    username = name;
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${name}" else "/home/${name}";
    stateVersion = "24.05";
  };
}
