{ config, ctx }:
let
  pkgs = ctx.pkgs;
  pkgs-stable = ctx.pkgs-stable;
  configHome = "${config.xdg.configHome}";
  homeManagerDirectory = "${configHome}/home-manager";
  env = import ./env.nix;
in
{
  home = {
    username = env.username;
    homeDirectory = env.homeDirectory;
    stateVersion = "25.11";
    sessionPath = [
      "$HOME/.local/bin"
    ];
  };

  # Audiverisは手動でインストールすること
  home.packages =
    (with pkgs-stable; [
      # pkgs.github-copilot-cli

      # LSPs
      pkgs.basedpyright
      pkgs.typescript-go
      gopls

      # CLI tools
      pkgs.magika
      aria2
      asciinema
      bat
      bindfs
      deno
      direnv
      # emacs-nox
      envchain
      eza
      ffmpeg
      gh
      gocryptfs
      home-manager
      imagemagick
      # jdupes errors on nixos 25.11
      jnv
      jq
      lazygit
      librsvg # rsvg-convert CLI
      litecli
      mmv-go
      nixfmt-rfc-style
      p7zip
      pandoc
      poppler-utils
      ripgrep
      ruby
      rustup
      sccache
      silicon
      tdf
      tmux
      tree-sitter
      typst
      uv
      vhs
      vim-startuptime
      wget
      yt-dlp

      # Fonts
      hackgen-nf-font
      ipaexfont
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      source-han-sans
      source-han-serif
      twemoji-color-font

      # (pkgs.writeShellScriptBin "trash" ''exec ${pkgs.deno}/bin/deno run -qA --no-config npm:trash-cli "$@"'')
      ctx.dot

      # Unused tools
      # comma
      # tectonic
      # slack-term
    ])
    ++ (
      if pkgs-stable.stdenv.isDarwin then
        with pkgs-stable;
        [
          # macOS specific packages
          cocoapods
          pkgs.container

          # GUI apps
          pkgs.alt-tab-macos
          # Uni - Pie style storage utility for macOS
          (pkgs-stable.stdenvNoCC.mkDerivation {
            pname = "uni-macos";
            version = "0.1.1";
            src = pkgs.fetchurl {
              url = "https://github.com/fiahfy/uni/releases/download/v0.1.1/Uni-0.1.1.dmg";
              sha256 = "1r9a856p2w99zsa6xi9pb3ydcc524ya0rxvzai0qh04cchm286xp";
            };
            nativeBuildInputs = [ pkgs-stable.undmg ];
            unpackPhase = ''undmg "$src"'';
            installPhase = ''
              mkdir -p "$out/Applications"
              cp -R *.app "$out/Applications/"
            '';
          })
        ]
      else
        with pkgs-stable;
        [
          pkgs.brave
          pkgs.codex
          pkgs.mise
          pkgs.wezterm

          # NOTE: For the following gnupg, install by homebrew because of compatibility with pinentry-mac on MacOS.
          gnupg
          # NOTE: In macOS, pnpm is installed by homebrew.
          nodejs
        ]
    );

  home.file = {
    ########################################
    # Common files
    ########################################

    ".skk/SKK-JISYO.L".source = "${pkgs.skkDictionaries.l}/share/skk/SKK-JISYO.L";
    ".latexmkrc".source = ./statics/latexmkrc;

    "${configHome}/wezterm".source =
      config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/syms/wezterm";
    "${configHome}/direnv".source =
      config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/syms/direnv";
    "${configHome}/lazygit".source =
      config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/syms/lazygit";
    "${configHome}/mise".source =
      config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/syms/mise";
    "${configHome}/nvim/lua".source =
      config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/nvim/lua";
    "${configHome}/nvim/after".source =
      config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/nvim/after";
    "${configHome}/fish/completions".source =
      config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/syms/fish_completions";
    "${configHome}/fish/functions".source =
      config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/syms/fish_functions";
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    SHELL = "${pkgs.fish}/bin/fish";
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";

    DIRENV_LOG_FORMAT = "";
    GOPATH = "${env.homeDirectory}/.go";
    RSPLUG_CONFIG_FILES = "${homeManagerDirectory}/nvim/rsplug/*.toml";
    RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
  };

  programs.neovim = {
    enable = true;
    initLua = "require 'init'";
  };

  programs.git = {
    enable = true;
    attributes = [
      "*.lockb binary diff=lockb"
      "*.ipynb binary diff=ipynb"
    ];
    ignores = [
      ".DS_Store"
      "kls_database.db"
      ".aider*"
    ];
    settings = {
      credential.helper = "/usr/local/share/gcm-core/git-credential-manager";
      init.defaultBranch = "main";
      commit.gpgSign = true;
      user = {
        signingKey = "B7E2A136"; # Expiration: 2025-09-01
        name = "gw31415";
        email = "24710985+gw31415@users.noreply.github.com";
      };
      diff.lockb.binary = true;
      diff.lockb.textconv = "${pkgs.bun}/bin/bun";
      diff.ipynb.binary = true;
    };
  };
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;
      character = {
        error_symbol = "[\\(](yellow)[´-_-](bold red)[\\)](yellow)[ =3](cyan)";
        success_symbol = "[\\(](yellow)[ 'u'](bold green)[\\)](yellow)[ =3](cyan)";
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
      c = "claude";
      dcd = "cd ${homeManagerDirectory}";
      gll = "lazygit";
      rp = "rsplug";
      sqlite3 = "litecli";
      tree = "eza -T";
      unitydroidlog = "adb logcat -s Unity ActivityManager PackageManager dalvikvm DEBUG";
    };
    shellAliases = {
      vi = "nvim";
      vim = "nvim";
    };
    plugins = [
      {
        name = "z";
        src = pkgs.fishPlugins.z.src;
      }
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair.src;
      }
      {
        name = "fish-na";
        src = (
          fetchTarball {
            url = "https://github.com/ryoppippi/fish-na/archive/refs/tags/v0.1.2.tar.gz";
            sha256 = "0dzchdawcpw307jszr5wiv5gj8mw9ai875g3n17kd7y4a8m0bgcy";
          }
        );
      }
    ];
    shellInit =
      (
        # macOS specific settings
        if pkgs.stdenv.isDarwin then
          ''
            if test -f /opt/homebrew/bin/brew
              eval (/opt/homebrew/bin/brew shellenv)
            end
            if test -d "/opt/homebrew/share/fish/completions"
              set -p fish_complete_path /opt/homebrew/share/fish/completions
            end
            if test -d "/opt/homebrew/share/fish/vendor_completions.d"
              set -p fish_complete_path /opt/homebrew/share/fish/vendor_completions.d
            end
            if test -d /Applications/Android\ Studio.app/Contents/jbr/Contents/Home
              export JAVA_HOME=/Applications/Android\ Studio.app/Contents/jbr/Contents/Home
            end
            if test -d "$HOME/Library/Android/sdk/platform-tools/"
              set -x PATH $HOME/Library/Android/sdk/platform-tools/ $PATH
            end
          ''
        else
          ""
      )
      + ''
        set fish_greeting
        if status is-interactive
          direnv hook fish | source
          mise activate fish | source
        else
          mise activate fish --shims | source
        end
        if test -f $HOME/.cargo/env.fish
          source "$HOME/.cargo/env.fish"
        end
        set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
        abbr -a n -f _na
      '';
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
  programs.pay-respects = {
    enable = true;
    enableFishIntegration = true;
  };
  manual.manpages.enable = true;
}
