{ config, pkgs, username, homeManagerPath, ... }:
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
    tectonic
    tmux
    typst
    wezterm
    wget
    yt-dlp
    zig
  ];

  home.file = {
    ".config" = {
      source = ./statics/config;
      recursive = true;
    };
    ".emacs.d" = {
      source = ./statics/emacs.d;
      recursive = true;
    };
    ".latexmkrc".source = ./statics/latexmkrc;
    # TODO: .Brewfile cannot be symlinked because it is not a directory
    ".Brewfile".source = ./statics/Brewfile;

    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${homeManagerPath}/syms/nvim";
    ".config/mise".source = config.lib.file.mkOutOfStoreSymlink "${homeManagerPath}/syms/mise";
    ".config/fish/completions".source = config.lib.file.mkOutOfStoreSymlink "${homeManagerPath}/syms/fish_completions";
    ".config/fish/functions".source = config.lib.file.mkOutOfStoreSymlink "${homeManagerPath}/syms/fish_functions";
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
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      # TOML_SCHEMA: "$schema" = 'https://starship.rs/config-schema.json'
      add_newline = true;
      character = {
        error_symbol = "[\\(](yellow)[´o_o](bold red)[\\)](yellow)[ =3](cyan)";
        success_symbol = "[\\(](yellow)[´‐_‐](bold green)[\\)](yellow)[ =3](cyan)";
      };
      directory = {
        truncate_to_repo = true;
        truncation_symbol = "…/";
      };
      time = {
        disabled = true;
      };
    };
  };
  programs.fish = {
    enable = true;
    shellAbbrs = {
      tree = "eza -T";
    };
    plugins = [
      { name = "z"; src = pkgs.fishPlugins.z.src; }
      { name = "autopair"; src = pkgs.fishPlugins.autopair.src; }
    ];
    shellInit = ''
      if test -f /opt/homebrew/bin/brew
        eval (/opt/homebrew/bin/brew shellenv)
      end
      # starship init fish | source
      if status is-interactive
        mise activate fish | source
      else
        mise activate fish --shims | source
      end
      if test -d /Applications/Android\ Studio.app/Contents/jbr/Contents/Home
        export JAVA_HOME=/Applications/Android\ Studio.app/Contents/jbr/Contents/Home
      end
      if test -f $HOME/.cargo/env.fish
        source "$HOME/.cargo/env.fish"
      end
    '';
  };
  programs.go = {
    enable = true;
    goPath = ".go";
  };
  home = {
    inherit username;
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
    stateVersion = "24.05";
  };
  manual.manpages.enable = true;
}
