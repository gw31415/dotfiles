{
  config,
  ctx,
  ...
}:
let
  pkgs = ctx.pkgs;
  env = import ./env.nix;
  packageGroups = import ./pkgs.nix { inherit ctx; };
  configHome = "${config.xdg.configHome}";
  homeManagerDirectory = "${configHome}/home-manager";
  managedSource =
    path:
    let
      relativePath = toString path;
      repoPath = "${homeManagerDirectory}/${relativePath}";
    in
    assert !(pkgs.lib.strings.hasPrefix "/" relativePath);
    config.lib.file.mkOutOfStoreSymlink repoPath;
in
{
  home = {
    username = env.username;
    # Linux では nix-darwin が無い素の home-manager のため /home 配下に落ち着ける。
    homeDirectory =
      if pkgs.stdenv.hostPlatform.isDarwin then env.homeDirectory else "/home/${env.username}";
    stateVersion = "26.05";
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.cargo/bin"
    ];
    packages = if pkgs.stdenv.hostPlatform.isDarwin then packageGroups.darwin else packageGroups.linux;
  };

  home.file = {
    ".skk/SKK-JISYO.L".source = "${pkgs.skkDictionaries.l}/share/skk/SKK-JISYO.L";
    ".latexmkrc".source = ../files/latexmkrc;

    "${configHome}/wezterm".source = managedSource "config/wezterm";
    "${configHome}/tunnel-client".source = managedSource "config/tunnel-client";
    "${configHome}/freeze".source = managedSource "config/freeze";
    "${configHome}/ghostty".source = managedSource "config/ghostty";
    "${configHome}/lazygit".source = managedSource "config/lazygit";
    "${configHome}/commitgen".source = managedSource "config/commitgen";
    "${configHome}/audiorouter".source = managedSource "config/audiorouter";
    "${configHome}/herdr".source = managedSource "config/herdr";
    "${configHome}/mise".source = managedSource "config/mise";
    "${configHome}/nvim/init.lua".text = "require 'init'";
    "${configHome}/nvim/lua".source = managedSource "config/nvim_lua";
    "${configHome}/nvim/after".source = managedSource "config/nvim_after";
    "${configHome}/fish/completions".source = managedSource "config/fish_completions";
    "${configHome}/fish/functions".source = managedSource "config/fish_functions";
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    SHELL = "${pkgs.fish}/bin/fish";
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";

    DIRENV_LOG_FORMAT = "";
    GOPATH = "${config.home.homeDirectory}/.go";
    RSPLUG_CONFIG_FILES = "${homeManagerDirectory}/config/nvim_rsplug/*.toml";
    RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
  };

  programs.git = {
    enable = true;
    attributes = [
      "* merge=mergiraf"
      "*.lockb binary diff=lockb"
      "*.ipynb binary diff=ipynb"
    ];
    ignores = [
      ".DS_Store"
      "kls_database.db"
      ".aider*"
      ".cocoindex_code"
      ".tgrep"
    ];
    settings = {
      merge = {
        conflictstyle = "diff3";
        mergiraf.name = "mergiraf";
        mergiraf.driver = "mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L";
      };
      core.pager = "hunk pager";
      init.defaultBranch = "main";
      commit.gpgSign = true;
      tag.gpgSign = true;
      gpg.format = "openpgp";
      user = {
        signingKey = "CF3AE17DB7E2A136";
        name = "gw31415";
        email = "24710985+gw31415@users.noreply.github.com";
      };
      diff.ipynb.binary = true;
      # GCM は macOS 側で導入されるため Darwin のみ。
    }
    // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      credential.helper = "/usr/local/share/gcm-core/git-credential-manager";
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
      # rg = "tgrep"; # tgrep はインデックス更新がないと意図しない結果となる
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
        src = packageGroups.sources.fish-na.src;
      }
      {
        name = "sponge";
        src = packageGroups.sources.sponge.src;
      }
      {
        name = "herdr_editor";
        src = packageGroups.sources.herdr_editor.src;
      }
    ];
    # NOTE: brew shellenv が先 (mise 本体は brew 導入のため、その後の mise activate より前が必須)。
    # Darwin のみ。Linux では空文字になる。
    shellInit =
      pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
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
      + ''
        set fish_greeting
        if status is-interactive
          mise activate fish | source
        else
          mise activate fish --shims | source
        end
        set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
        set -x GITHUB_TOKEN (gh auth token)
        abbr -a n -f _na

        bind \ea __fishify_replace_buffer
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

  manual.manpages.enable = pkgs.lib.mkDefault true;
  # man package が null の構成ではキャッシュ生成は無意味なため明示的に切る (挙動不変)。
  programs.man.generateCaches = false;
}
