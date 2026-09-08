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
  imports = [ ./brew.nix ];

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

  ########################################
  # tunnel-client (OpenAI MCP control-plane tunnel)
  ########################################
  # ローカル MCP サーバー (local-mcp) を OpenAI の制御プレーンへ常駐トンネルする。
  # プロファイル local-mcp-stdio は api_key を env:CONTROL_PLANE_API_KEY で参照するため、
  # 起動時に ~/.env を source してランタイム解決する (シークレットを nix store に焼かない)。
  # local-mcp は tunnel-client から PATH 経由で起動されるため mise shims を通す。
  launchd.user.agents.tunnel-client = {
    serviceConfig = {
      ProgramArguments = [
        "${ctx.pkgs.writeShellScript "tunnel-client-run" ''
          set -eo pipefail
          if [[ -f "$HOME/.env" ]]; then
            set -a
            set +u
            source "$HOME/.env"
            set -u
            set +a
          fi
          export PATH="$HOME/.local/share/mise/shims:$PATH"
          exec "${env.homeDirectory}/.local/share/mise/installs/github-openai-tunnel-client/latest/tunnel-client" \
            run --profile local-mcp-stdio
        ''}"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${env.homeDirectory}/Library/Logs/tunnel-client/tunnel-client.log";
      StandardErrorPath = "${env.homeDirectory}/Library/Logs/tunnel-client/tunnel-client.error.log";
    };
  };
}
