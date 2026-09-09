# mise で実現できないライブラリ性の高い共有ツール (Linux 用 buildEnv)。
# 開発 CLI・日常 CLI は mise (config/mise/config.toml) が正。
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
    # ビルドチェイン土台 (cargo / go 等の source build 用)。
    stdenv.cc
    binutils
    gettext
    openssl
    pkgconf
    zlib
  ];
}
