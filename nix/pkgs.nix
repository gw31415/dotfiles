{ ctx }:
let
  pkgs = ctx.pkgs-stable;
  # nvfetcher 管理 (fish プラグイン)。更新時は `cd vendor && nvfetcher`。
  sources = import ../vendor/generated.nix {
    inherit (pkgs)
      dockerTools
      fetchFromGitHub
      fetchgit
      fetchurl
      ;
  };
in
rec {
  inherit sources;

  # 開発 CLI・日常 CLI は mise が正。ここに残すのは mise に backend が無いものだけ。
  # mise 移管済み (config/mise/config.toml):
  #   言語: node/go/python/ruby/deno/uv/pnpm
  #   LSP/Fmt: basedpyright/gopls/tree-sitter/stylua/mergiraf/fish-lsp
  #   CLI: gh/lazygit/jq/jnv/yt-dlp/pandoc/silicon/vhs/litecli/ollama/claude/codex/
  #     bat/eza/tmux/ffmpeg/imagemagick/7zip/asciinema/
  #     tdf(cargo)/mmv-go(go)/vim-startuptime(go)/poppler(conda)/librsvg(conda)
  # 削除 (参照なし・代替あり): wget・aria2 /
  #   p7zip (7zip の 7zz に交代)
  common = with pkgs; [
    # Nix 固有
    ctx.dot
    comma
    home-manager
    nixfmt
    nvfetcher

    # Fonts (両 OS 共通で Nix 管理)。
    hackgen-nf-font
    ipaexfont
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    source-han-sans
    source-han-serif
    twemoji-color-font

    # Linux & macOS 共通 かつ mise 不在
    bindfs
    direnv
    envchain
    gocryptfs # Linux はあるが macOS のビルドが不在
    openssh
  ];

  darwinPkgs = [
    # macOS 固有のパッケージ (Nix 管理)。
  ];

  # 素の Linux (nix-darwin なし) 用。方針: mise/gnupg は macOS=brew・Linux=Nix。
  # brew にあって Linux に無いものはここで Nix 補完する (mac の Nix には混入させない)。
  # 対応表 (brew → Nix):
  #   mise → mise / gnupg → gnupg / openssl@3 → openssl /
  #   gettext → gettext / libgpg-error → libgpg-error / pkgconf → pkgconf /
  #   pinentry-mac → pinentry-curses (Linux に Touch ID は無いため curses 版)
  # 対象外 (macOS 専用): mas, pinentry-touchid, xcode-build-server, codexbar,
  #   cocoapods, casks GUI 全般
  # 開発 CLI は mise 側。
  linuxPkgs = with pkgs; [
    fish
    gnupg
    mise
    bash
    binutils
    openssl
    gettext
    libgpg-error
    pinentry-curses
    pkgconf
  ];

  darwin = common ++ darwinPkgs;
  linux = common ++ linuxPkgs;
}
