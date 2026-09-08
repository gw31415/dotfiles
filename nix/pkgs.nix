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

  # ponytail: 開発 CLI は mise が正。ここは起動基盤 + Nix でしか安定しないもののみ。
  # mise に移管済み: basedpyright/gopls/deno/ollama/gh/lazygit/jq/jnv/mergiraf/
  #   tree-sitter/uv/ruby/pandoc/yt-dlp/vhs/litecli/claude/codex
  # fonts は Linux のみ (macOS は brew font-* cask)。
  # cocoapods は brew へ移動。
  common = with pkgs-stable; [
    # nixpkgs-stable の direnv 2.37.1 は Darwin で cgo 無効のまま
    # external link を要求してビルドに失敗するため、unstable 側を使う。
    pkgs.direnv
    pkgs.nvfetcher

    # B 案 shell 生存セット (非対話 shell の shim 遅延回避のため Nix 残留)。
    bat
    eza

    comma
    envchain
    nixfmt
    home-manager
    tmux
    openssh

    # ダウンロード・メディア・暗号化基盤 (バージョン切替不要のため Nix 残留)。
    aria2
    wget
    ffmpeg
    imagemagick
    librsvg
    poppler-utils
    p7zip
    gocryptfs
    bindfs

    # 小物 (mise 化の利が薄いため Nix 残留)。
    asciinema
    mmv-go
    tdf
    vim-startuptime

    # Development 基盤 (例外・Nix 固有)。
    ctx.dot
    sccache
    rustup
  ];

  darwinPkgs = with pkgs-stable; [
    container
  ];

  # 素の Linux (nix-darwin なし) 用。mise 本体と、brew で担う GPG/TLS 系の
  # 代替 (gnupg)、素の Linux に無い shell 基盤 (fish/bash/binutils) を足す。
  # fonts は Linux のみ Nix で持つ。開発 CLI は mise 側。
  linuxPkgs =
    (with pkgs; [
      fish
      gnupg
      mise
      bash
      binutils
    ])
    ++ (with pkgs-stable; [
      hackgen-nf-font
      ipaexfont
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      source-han-sans
      source-han-serif
      twemoji-color-font
    ]);

  darwin = common ++ darwinPkgs;
  linux = common ++ linuxPkgs;
}
