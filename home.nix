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
    stateVersion = "25.05";
  };

  # Audiverisは手動でインストールすること
  home.packages =
    (with pkgs-stable; [
      pkgs.nodejs
      pkgs.gemini-cli

      # CLI tools
      aria2
      asciinema
      bat
      bindfs
      bun
      comma
      deno
      emacs-nox
      envchain
      era
      eza
      ffmpeg
      flyctl
      gh
      gnupg
      gocryptfs
      gopls
      home-manager
      hugo
      imagemagick
      jdupes
      jnv
      jq
      lazygit
      librsvg # rsvg-convert CLI
      litecli
      mise
      mmv-go
      nixfmt-rfc-style
      p7zip
      pandoc
      poppler_utils
      python3
      ripgrep
      ruby
      rustup
      sccache
      silicon
      slack-term
      tectonic
      tdf
      tmux
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

      (pkgs.writeShellScriptBin "trash" ''exec ${pkgs.deno}/bin/deno run -qA --no-config npm:trash-cli "$@"'')
      ctx.dot
    ])
    ++ (
      if pkgs-stable.stdenv.isDarwin then
        with pkgs-stable;
        [
          # macOS specific packages
          cocoapods
        ]
      else
        [ ]
    );

  home.file = {
    ########################################
    # Common files
    ########################################

    ".skk/SKK-JISYO.L".source = "${pkgs.skkDictionaries.l}/share/skk/SKK-JISYO.L";
    ".emacs.d" = {
      source = ./statics/emacs.d;
      recursive = true;
    };
    ".latexmkrc".source = ./statics/latexmkrc;

    ".nix-deliverables/wezterm-types".source = "${import ./wezterm-types/default.nix {
      inherit pkgs;
    }}";

    "${configHome}/wezterm".source =
      config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/syms/wezterm";
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
    RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
    SHELL = "${pkgs.fish}/bin/fish";
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    DIRENV_LOG_FORMAT = "";
    TEST_TEXT = "${config.home.homeDirectory}";
  };

  programs.nixvim =
    let
      dpp-vim = pkgs.vimUtils.buildVimPlugin {
        name = "dpp.vim";
        src = ctx.dpp-vim;
      };
      dpp-ext-installer = pkgs.vimUtils.buildVimPlugin {
        name = "dpp-ext-installer";
        src = ctx.dpp-ext-installer;
      };
      dpp-ext-lazy = pkgs.vimUtils.buildVimPlugin {
        name = "dpp-ext-lazy";
        src = ctx.dpp-ext-lazy;
      };
      dpp-ext-toml = pkgs.vimUtils.buildVimPlugin {
        name = "dpp-ext-toml";
        src = ctx.dpp-ext-toml;
      };
      dpp-protocol-git = pkgs.vimUtils.buildVimPlugin {
        name = "dpp-protocol-git";
        src = ctx.dpp-protocol-git;
      };
    in
    {
      package = ctx.neovim-nightly-overlay.packages.${pkgs.system}.default;
      enable = true;
      colorschemes.monokai-pro = {
        enable = true;
        settings = {
          transparent_background = true;
        };
      };
      extraConfigLuaPost = ''
        vim.opt.runtimepath:prepend '${pkgs.vimPlugins.denops-vim}'
        vim.opt.runtimepath:prepend '${dpp-vim}'
        vim.opt.runtimepath:append '${dpp-ext-toml}'
        vim.opt.runtimepath:append '${dpp-protocol-git}'
        vim.opt.runtimepath:append '${dpp-ext-lazy}'
        vim.opt.runtimepath:append '${dpp-ext-installer}'

        local dpp = require 'dpp'
        local dpp_base = '~/.cache/dpp'
        if dpp.load_state(dpp_base) then
          vim.opt.runtimepath:prepend '${pkgs.vimPlugins.denops-vim}'
          vim.api.nvim_create_autocmd('User', {
            pattern = 'DenopsReady',
            callback = function()
              dpp.make_state(dpp_base, '~/.config/home-manager/nvim/dpp.ts')
            end
          })
        end

        require 'init'
      '';
    };

  programs.git = {
    enable = true;
    attributes = [
      "*.lockb binary diff=lockb"
      "*.ipynb binary diff=ipynb"
    ];
    userName = "gw31415";
    userEmail = "gw31415@amas.dev";
    delta.enable = true;
    ignores = [
      ".DS_Store"
      "kls_database.db"
    ];
    extraConfig = {
      credential.helper = "/usr/local/share/gcm-core/git-credential-manager";
      init.defaultBranch = "main";
      commit.gpgSign = true;
      user.signingKey = "B7E2A136"; # Expiration: 2025-09-01
      diff.lockb.binary = true;
      diff.lockb.textconv = "${pkgs.bun}/bin/bun";
      diff.ipynb.binary = true;
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
            url = "https://github.com/ryoppippi/fish-na/archive/refs/tags/v0.1.1.tar.gz";
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
  manual.manpages.enable = true;
}
