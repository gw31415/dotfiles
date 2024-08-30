{ config, pkgs, env, ... }:
{
  home.packages = with pkgs; [
    aria2
    asciinema
    bat
    carbon-now-cli
    chezmoi
    cocoapods
    delta
    deno
    direnv
    dotnet-sdk_7
    emacs
    eza
    ffmpeg
    flyctl
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
    poppler_utils
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
    ########################################
    # Common files
    ########################################

    ".skk/SKK-JISYO.L" = {
      source = "${pkgs.skk-dicts}/share/SKK-JISYO.L";
    };
    ".config" = {
      source = ./statics/config;
      recursive = true;
    };
    ".emacs.d" = {
      source = ./statics/emacs.d;
      recursive = true;
    };
    ".latexmkrc".source = ./statics/latexmkrc;

    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${env.homeManagerDirectory}/syms/nvim";
    ".config/mise".source = config.lib.file.mkOutOfStoreSymlink "${env.homeManagerDirectory}/syms/mise";
    ".config/fish/completions".source = config.lib.file.mkOutOfStoreSymlink "${env.homeManagerDirectory}/syms/fish_completions";
    ".config/fish/functions".source = config.lib.file.mkOutOfStoreSymlink "${env.homeManagerDirectory}/syms/fish_functions";

  } // (if pkgs.stdenv.isDarwin then {
    ########################################
    # macOS specific files
    ########################################

    # TODO: .Brewfile cannot be symlinked because it is not a directory
    ".Brewfile".source = ./statics/Brewfile;

    # TODO: Files in the Containers directory cannot be symlinked.
    # "Library/Containers/net.mtgto.inputmethod.macSKK/Data/Documents/Settings/kana-rule.conf".source = ./statics/kana-rule.conf;

  } else { });

  home.sessionVariables = {
    EDITOR = "nvim";
    RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
    SHELL = "${pkgs.fish}/bin/fish";
  };

  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    userName = "gw31415";
    userEmail = "gw31415@amas.dev";
    delta.enable = true;
    ignores = [
      ".DS_Store"
      "kls_database.db"
    ];
    extraConfig = {
      credential.helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
      init.defaultBranch = "main";
    };
  };
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;
      character = {
        error_symbol = "[\\(](yellow)[´o_o](bold red)[\\)](yellow)[ =3](cyan)";
        success_symbol = "[\\(](yellow)[´‐_‐](bold green)[\\)](yellow)[ =3](cyan)";
      };
      directory = {
        truncate_to_repo = true;
        truncation_symbol = "󰟐 :";
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
      if status is-interactive
        mise activate fish | source
      else
        mise activate fish --shims | source
      end

      if test -f $HOME/.cargo/env.fish
        source "$HOME/.cargo/env.fish"
      end
    '' + (
      # macOS specific settings
      if pkgs.stdenv.isDarwin then ''
        if test -f /opt/homebrew/bin/brew
          eval (/opt/homebrew/bin/brew shellenv)
        end
        if test -d /Applications/Android\ Studio.app/Contents/jbr/Contents/Home
          export JAVA_HOME=/Applications/Android\ Studio.app/Contents/jbr/Contents/Home
        end
      '' else ""
    );
  };
  programs.go = {
    enable = true;
    goPath = ".go";
  };
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    defaultCommand = "fd --type f --hidden --exclude .git --follow --color=always";
    defaultOptions = [ "--ansi" ];
  };
  programs.fd = {
    enable = true;
    ignores = [
      ".local"
      ".cache"
      ".cargo"
      "node_modules"
      "Library"
      "OrbStack"
    ];
  };
  home = {
    username = env.username;
    homeDirectory = env.homeDirectory;
    stateVersion = "24.05";
  };
  manual.manpages.enable = true;
}
