# mise で実現できないライブラリ性の高い共有ツール (Linux 用 buildEnv)。
# 開発 CLI・日常 CLI は mise (config/mise/config.toml) が正。
# Nix が無い Linux では任意レイヤーとして省略できる。
# 導入: `nix profile install .#shared`
{ pkgs }:
pkgs.buildEnv {
  name = "dotfiles-shared";
  paths = with pkgs; [
    git
    gnupg
    libgpg-error
    pinentry-curses
    openssh
    fuse3
    bindfs
    gocryptfs
    # mise 経由の language server / Mason が必要に応じて source build するための土台。
    stdenv.cc
    gcc
    binutils
    unzip
    wget
    gettext
    openssl
    pkgconf
    zlib
    # Nix 言語専用の formatter。kakehashi/nil の command から参照する。
    nixfmt
  ];
}
