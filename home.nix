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
    stateVersion = "24.05";
  };

  home.packages = (with pkgs-stable; [
    pkgs.tdf

    # CLI tools
    aria2
    asciinema
    bat
    bindfs
    bun
    carbon-now-cli
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
    nodejs
    p7zip
    pandoc
    poppler_utils
    python3
    ripgrep
    rustup
    sccache
    silicon
    slack-term
    tectonic
    tmux
    typst
    vhs
    vim-startuptime
    wget
    yt-dlp

    # Fonts
    hackgen-nf-font
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif

    (pkgs.writeShellScriptBin "czg" ''exec ${pkgs.deno}/bin/deno run -qA --no-config npm:czg "$@"'')
    (pkgs.writeShellScriptBin "trash" ''exec ${pkgs.deno}/bin/deno run -qA --no-config npm:trash-cli "$@"'')
    ctx.dot
  ]) ++ (if pkgs-stable.stdenv.isDarwin then with pkgs-stable; [
    # macOS specific packages
    cocoapods
  ] else [ ]);

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

    ".nix-deliverables/wezterm-types".source = "${import ./wezterm-types/default.nix { inherit pkgs;}}";

    "${configHome}/wezterm".source = config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/syms/wezterm";
    "${configHome}/lazygit".source = config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/syms/lazygit";
    "${configHome}/mise".source = config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/syms/mise";
    "${configHome}/nvim/lua".source = config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/nvim/lua";
    "${configHome}/fish/completions".source = config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/syms/fish_completions";
    "${configHome}/fish/functions".source = config.lib.file.mkOutOfStoreSymlink "${homeManagerDirectory}/syms/fish_functions";
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
      src = pkgs.fetchFromGitHub {
        owner = "Shougo";
        repo = "dpp.vim";
        rev = "188f2852326d2e962f9afbf92d5bcb395ca2cb56";
        hash = "sha256-UsKiSu0wtC0vdb7DZfvfrbqeHVXx5OPS/L2f/iABIWw=";
      };
    };
    dpp-ext-installer = pkgs.vimUtils.buildVimPlugin {
      name = "dpp-ext-installer";
      src = pkgs.fetchFromGitHub {
        owner = "Shougo";
        repo = "dpp-ext-installer";
        rev = "af4c066a9d9c8ba6938810556184fdec413063f1";
        hash = "sha256-8jY5k/zEIXcIfqsMVfQXUvApRnJWavV4UmD9TCwMGv8=";
      };
    };
    dpp-ext-lazy = pkgs.vimUtils.buildVimPlugin {
      name = "dpp-ext-lazy";
      src = pkgs.fetchFromGitHub {
        owner = "Shougo";
        repo = "dpp-ext-lazy";
        rev = "839e74094865bdb2a548f1f43ab2752243182d31";
        hash = "sha256-Izgv61SLT096WaPauWFdIKgXZWomGSC9NinciAQEIx4=";
      };
    };
    dpp-ext-toml = pkgs.vimUtils.buildVimPlugin {
      name = "dpp-ext-toml";
      src = pkgs.fetchFromGitHub {
        owner = "Shougo";
        repo = "dpp-ext-toml";
        rev = "b6e4b8dbe27fb8fab838c8898c8d329dceb7b759";
        hash = "sha256-0qtL8tY4v3Vk/7cJahhg0+tLF6EM+U8A9R8OjzWSUyY=";
      };
    };
    dpp-protocol-git = pkgs.vimUtils.buildVimPlugin {
      name = "dpp-protocol-git";
      src = pkgs.fetchFromGitHub {
        owner = "Shougo";
        repo = "dpp-protocol-git";
        rev = "a5f8e67c1eefb009e7067f74d0615597e91a6c86";
        hash = "sha256-BZeO5uedLeyCAPD1SvXk/nPIjTn1LuIAlGQAu4u65Qk=";
      };
    };
  in
  {
    enable = true;
    colorschemes.onedark = {
      enable = true;
      settings = {
        transparent = true;
      };
    };
    extraPlugins = [
      pkgs.vimPlugins.denops-vim
    ];
    extraConfigLuaPost = ''
      vim.opt.runtimepath:prepend '${dpp-vim}'

      local dpp = require 'dpp'
      local dpp_base = '~/.cache/dpp'

      vim.opt.runtimepath:append '${dpp-ext-toml}'
      vim.opt.runtimepath:append '${dpp-protocol-git}'
      vim.opt.runtimepath:append '${dpp-ext-lazy}'
      vim.opt.runtimepath:append '${dpp-ext-installer}'

      if dpp.load_state(dpp_base) then
        -- vim.opt.runtimepath:prepend '$HOME/.cache/dpp/repos/github.com/vim-denops/denops.vim'

        vim.api.nvim_create_autocmd('User', {
          pattern = 'DenopsReady',
          callback = function()
            dpp.make_state(dpp_base, '${homeManagerDirectory}/nvim/dpp.ts')
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
      credential.helper =
        "/usr/local/share/gcm-core/git-credential-manager";
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
      tree = "eza -T";
      gll = "lazygit";
      dcd = "cd ${homeManagerDirectory}";
      unitydroidlog = "adb logcat -s Unity ActivityManager PackageManager dalvikvm DEBUG";
    };
    shellAliases = {
      vi = "nvim";
      vim = "nvim";
    };
    plugins = [
      { name = "z"; src = pkgs.fishPlugins.z.src; }
      { name = "autopair"; src = pkgs.fishPlugins.autopair.src; }
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
    shellInit = (
      # macOS specific settings
      if pkgs.stdenv.isDarwin then ''
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
      '' else ""
    ) + ''
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
