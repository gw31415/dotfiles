{ ctx, ... }:
let
  env = import ./env.nix;

  # cli.ts は nixpkgs の vimPlugins.denops-vim に同梱されている
  # (denops/@denops-private/cli.ts)。rsplug の worktree ハッシュはコミット毎に
  # 変わるため、固定パスとして参照するには nixpkgs 由来のストアパスが最も安定。
  denopsVim = ctx.pkgs.vimPlugins.denops-vim;
  denopsCli = "${denopsVim}/denops/@denops-private/cli.ts";
in
{
  ########################################
  # Requires for nix-darwin to work
  ########################################
  system.stateVersion = 4;
  system.primaryUser = env.username;
  nixpkgs.hostPlatform = ctx.system;

  # REQUIRED: To keep-enabled experimental features after installation, since nix is managed by nix-darwin.
  nix.settings = {
    experimental-features = "nix-command flakes";
    trusted-users = [
      "root"
      "${env.username}"
    ];
  };

  # REQUIRED: Because this dotfiles is intended for a nix-darwin multi-user environment.
  nix.package = ctx.pkgs.nix;

  # REQUIRED: Create /etc/fish that loads the nix-darwin environment.
  programs.fish.enable = true;

  ########################################
  # Configuration for macOS system
  ########################################
  system.defaults = {
    finder = {
      AppleShowAllExtensions = true;
      CreateDesktop = true;
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
      ShowStatusBar = false;
    };
    dock = {
      autohide = true;
      show-recents = false;
      tilesize = 50;
      magnification = true;
      largesize = 64;
      orientation = "bottom";
      launchanim = false;
    };
  };

  security.pam.services.sudo_local = {
    enable = true;
    reattach = true;
    touchIdAuth = true;
    watchIdAuth = true;
  };

  ########################################
  # Homebrew
  ########################################

  homebrew = {
    enable = true;
    onActivation.autoUpdate = false;
    taps = [
      "homebrew/bundle"
      "homebrew/core"
      "homebrew/services"
      "jorgelbg/tap"
      "arto-app/tap"
      "anomalyco/tap"
      "macos-fuse-t/homebrew-cask"
      "steipete/tap"
    ];
    brews = [
      "openssl@3"
      "gettext"
      "gnupg"
      "libgpg-error"
      "mas"
      "opencode"
      "pinentry-mac"
      "pkgconf"
      "xcode-build-server"
      "jorgelbg/tap/pinentry-touchid"
      "steipete/tap/codexbar"
    ];
    # メモ： MTG補助用AI - Cluely はCaskなし (https://cluely.com/)
    casks = [
      "arto"
      # "affinity"
      "anki"
      # "brave-browser"
      "blackhole-2ch"
      "claude"
      "codex"
      "codex-app"
      "discord"
      "dockdoor"
      # "figma"
      "gnucash"
      "keybase"
      "macfuse"
      "macskk"
      # "macshot" # QWERTY以外でショートカットキーが異なる不具合
      # "microsoft-teams"
      "music-decoy"
      "musicbrainz-picard"
      # "opencode-desktop"
      "puremac"
      "slack"
      "smoothcsv"
      "thaw"
      "google-chrome"
      "ghostty"
      "vorssaint"
      # "android-studio"
      # "container"
      # "cursor"
      # "devtoys"
      # "gather"
      # "keepassxc"
      # "obs"
      "obsidian"
      # "piphero"
      # "postman"
      # "secretive"
      "zoom"

      # Home Manager GUI apps
      # "microsoft-auto-update"
      # "orbstack"
    ];
    masApps = {
      "1Blocker" = 1365531024;
      "Amphetamine" = 937984704;
      # "Goodnotes" = 1444383602;
      "Keynote" = 409183694;
      "LINE" = 539883307;
      "Logic Pro" = 634148309;
      "Ice Cubes for Mastodon" = 6444915884;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "RunCat" = 1429033973;
      "Xcode" = 497799835;
      "タイピスト" = 415166115;
      "宛名印刷" = 1598123076;

      # Pro Apps
      # "Compressor" = 424390742;
      # "Final Cut Pro" = 424389933;
      # "MainStage" = 634159523;
      # "Motion" = 434290957;
    };
  };

  ########################################
  # Auto install software updates
  ########################################
  system.activationScripts.extraActivation.text = ''
    softwareupdate --all --download --background

    # activation スクリプトはクリーン環境で実行され PATH に
    # /opt/homebrew/bin が含まれないため、明示的に先頭に追加する。
    # これにより mise や pinentry-mac（pinentry-touchid -fix が内部で参照）が解決される。
    export PATH=/opt/homebrew/bin:$PATH

    # pinentry-touchid falls back to the Homebrew `pinentry` formula's
    # default pinentry. Keep it pointed at pinentry-mac so GPG commit signing
    # can show the macOS/Touch ID prompt after Homebrew upgrades/relinks.
    #
    # `pinentry-touchid -fix` spawns pinentry-mac and bridges it over Assuan,
    # printing "OK Hi from pinentry-mac!". In the non-interactive activation
    # shell that spawned pinentry-mac then blocks forever waiting on the
    # Assuan handshake -> `darwin-rebuild switch` hangs. So: close stdin so the
    # spawned pinentry-mac sees EOF and exits, and bound the whole thing with a
    # kill timer so a future relink still gets fixed without stalling the build.
    if [ -x /opt/homebrew/bin/pinentry-touchid ]; then
      /opt/homebrew/bin/pinentry-touchid -fix </dev/null >/dev/null 2>&1 &
      _pe_pid=$!
      _pe_wait=0
      while kill -0 "$_pe_pid" 2>/dev/null; do
        _pe_wait=$((_pe_wait + 1))
        if [ "$_pe_wait" -ge 10 ]; then
          kill "$_pe_pid" 2>/dev/null
          wait "$_pe_pid" 2>/dev/null
          break
        fi
        sleep 1
      done
    fi

    mise i && mise up --bump
  '';

  ########################################
  # denops Shared Server
  ########################################
  # Neovim の denops プラグインが接続する共通 Deno サーバーを常駐させる。
  # Vim/Neovim 起動毎に Deno プロセスを spawn するオーバーヘッドが消え、
  # skkeleton / vim-gin / fuzzy-motion 等の denops 系プラグインが即座に使える。
  # 詳細: https://github.com/vim-denops/denops.vim/wiki または :help denops-shared-server
  launchd.user.agents.denops-shared-server = {
    serviceConfig = {
      ProgramArguments = [
        "${ctx.pkgs.deno}/bin/deno"
        "run"
        "-A"
        "--no-lock"
        "-q"
        denopsCli
        "--hostname"
        "127.0.0.1"
        "--port"
        "32123"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${env.homeDirectory}/Library/Logs/denops-shared-server.log";
      StandardErrorPath = "${env.homeDirectory}/Library/Logs/denops-shared-server.log";
    };
  };
}
