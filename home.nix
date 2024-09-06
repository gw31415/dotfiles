{ config, pkgs, env, dot-cli, ... }:
{
  home.packages = with pkgs; [
    # CLI tools
    aria2
    asciinema
    bat
    carbon-now-cli
    chezmoi
    cocoapods
    delta
    deno
    dotnet-sdk_7
    emacs-nox
    envchain
    eza
    ffmpeg
    flyctl
    gh
    gopls
    hugo
    imagemagick
    jdupes
    jnv
    jq
    lazygit
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
  ] ++ [
    # Fonts
    hackgen-nf-font
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
  ]
  ++ [ dot-cli ];

  home.file =
    let
      configHome = "${config.xdg.configHome}";
      homeManagerDirectory = "${configHome}/home-manager";
    in
    {
      ########################################
      # Common files
      ########################################

      ".skk/SKK-JISYO.L" = {
        source = "${pkgs.skk-dicts}/share/SKK-JISYO.L";
      };
      ".emacs.d" = {
        source = ./statics/emacs.d;
        recursive = true;
      };
      ".latexmkrc".source = ./statics/latexmkrc;

      "${configHome}" = {
        source = ./statics/config;
        recursive = true;
      };

      "${configHome}/lazygit".source = config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/syms/lazygit";
      "${configHome}/mise".source = config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/syms/mise";
      "${configHome}/nvim".source = config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/syms/nvim";
      "${configHome}/fish/completions".source = config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/syms/fish_completions";
      "${configHome}/fish/functions".source = config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/syms/fish_functions";

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
    XDG_CONFIG_HOME = "${env.homeDirectory}/.config";
    DIRENV_LOG_FORMAT = "";
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
      credential.helper =
        "/usr/local/share/gcm-core/git-credential-manager";
      init.defaultBranch = "main";
      commit.gpgSign = true;
      user.signingKey = "B7E2A136"; # Expiration: 2025-09-01
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
      gll = "lazygit";
    };
    plugins = [
      { name = "z"; src = pkgs.fishPlugins.z.src; }
      { name = "autopair"; src = pkgs.fishPlugins.autopair.src; }
    ];
    shellInit = ''
      set fish_greeting
      if test -d "/opt/homebrew/share/fish/completions"
          set -p fish_complete_path /opt/homebrew/share/fish/completions
      end
      if test -d "/opt/homebrew/share/fish/vendor_completions.d"
          set -p fish_complete_path /opt/homebrew/share/fish/vendor_completions.d
      end

      if status is-interactive
          mise activate fish | source
      else
          mise activate fish --shims | source
      end

      if test -f $HOME/.cargo/env.fish
          source "$HOME/.cargo/env.fish"
      end

      if type -q gpgconf
          set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
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
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
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
