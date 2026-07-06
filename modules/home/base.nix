{
  config,
  ctx,
  target,
  ...
}:
let
  pkgs = ctx.pkgs;
  env = import ../../env.nix;
  packageGroups = import ./packages.nix { inherit ctx; };
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
    homeDirectory = env.homeDirectory;
    stateVersion = "25.11";
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.cargo/bin"
    ];
    packages = packageGroups.forTarget target;
  };

  home.file = {
    ".skk/SKK-JISYO.L".source = "${pkgs.skkDictionaries.l}/share/skk/SKK-JISYO.L";
    ".latexmkrc".source = ./../../statics/latexmkrc;

    "${configHome}/wezterm".source = managedSource "syms/wezterm";
    "${configHome}/direnv".source = managedSource "syms/direnv";
    "${configHome}/ghostty".source = managedSource "syms/ghostty";
    "${configHome}/lazygit".source = managedSource "syms/lazygit";
    "${configHome}/commitgen".source = managedSource "syms/commitgen";
    "${configHome}/audiorouter".source = managedSource "syms/audiorouter";
    "${configHome}/herdr".source = managedSource "syms/herdr";
    "${configHome}/mise".source = managedSource "syms/mise";
    "${configHome}/nvim/lua".source = managedSource "nvim/lua";
    "${configHome}/nvim/after".source = managedSource "nvim/after";
    "${configHome}/fish/completions".source = managedSource "syms/fish_completions";
    "${configHome}/fish/functions".source = managedSource "syms/fish_functions";
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    SHELL = "${pkgs.fish}/bin/fish";
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";

    DIRENV_LOG_FORMAT = "";
    GOPATH = "${config.home.homeDirectory}/.go";
    RSPLUG_CONFIG_FILES = "${homeManagerDirectory}/nvim/rsplug/*.toml";
    RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
  };

  programs.neovim = {
    enable = true;
    initLua = "require 'init'";
    withPython3 = false;
    withRuby = false;
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
    ];
    settings = {
      merge = {
        conflictstyle = "diff3";
        mergiraf.name = "mergiraf";
        mergiraf.driver = "mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L";
      };
      core.pager = "hunk pager";
      init.defaultBranch = "main";
      commit.gpgSign = target != "linux-container";
      tag.gpgSign = true;
      gpg.format = "openpgp";
      user = {
        signingKey = "CF3AE17DB7E2A136";
        name = "gw31415";
        email = "24710985+gw31415@users.noreply.github.com";
      };
      diff.lockb.binary = true;
      diff.lockb.textconv = "${pkgs.bun}/bin/bun";
      diff.ipynb.binary = true;
    };
  };

  programs.fish = {
    enable = true;
    shellAbbrs = {
      dcd = "cd ${homeManagerDirectory}";
      # g = "bit";
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
    shellInit = ''
      set fish_greeting
      if status is-interactive
        direnv hook fish | source
        mise activate fish | source
      else
        mise activate fish --shims | source
      end
      set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
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
}
