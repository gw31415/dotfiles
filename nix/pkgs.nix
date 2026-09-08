{ ctx }:
let
  pkgs = ctx.pkgs;
  pkgs-stable = ctx.pkgs-stable;
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

  common = with pkgs-stable; [
    # LSPs
    pkgs.basedpyright
    gopls

    # nixpkgs-stable の direnv 2.37.1 は Darwin で cgo 無効のまま
    # external link を要求してビルドに失敗するため、unstable 側を使う。
    pkgs.direnv
    pkgs.nvfetcher
    pkgs.ollama
    aria2
    asciinema
    bat
    bindfs
    comma
    deno
    envchain
    eza
    ffmpeg
    gh
    gocryptfs
    home-manager
    imagemagick
    jnv
    jq
    lazygit
    librsvg
    litecli
    mergiraf
    mmv-go
    nixfmt-rfc-style
    p7zip
    pandoc
    poppler-utils
    ruby
    silicon
    tdf
    tmux
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

    # Development tools
    ctx.dot
    sccache
    tree-sitter
    rustup
  ];

  darwinPkgs = with pkgs-stable; [
    cocoapods
    container
  ];

  # 素の Linux (nix-darwin なし) 用。mise 本体と、brew で担う GPG/TLS 系の
  # 代替 (gnupg)、素の Linux に無い shell 基盤 (fish/bash/binutils) を足す。
  # rsplug は mise 側で導入 (FHS 問題は旧コンテナ特有で素の Linux では起きない)。
  linuxPkgs = with pkgs; [
    fish
    claude
    codex
    gnupg
    mise
    bash
    binutils
  ];

  darwin = common ++ darwinPkgs;
  linux = common ++ linuxPkgs;
}
