{ ctx }:
let
  pkgs = ctx.pkgs;
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

  # NOTE: 開発 CLI・日常 CLI は基本的に mise をつかうこと
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
    gocryptfs # Linux はあるが macOS が不在
    openssh
  ];

  darwinPkgs = [
    # macOS 固有のパッケージ (Nix 管理)。
  ];

  # Linux 固有のパッケージ (Nix 管理)。
  linuxPkgs = with pkgs; [
    binutils
    fish
    gettext
    gnupg
    libgpg-error
    mise
    openssl
    pinentry-curses
    pkgconf
    zsh
  ];

  darwin = common ++ darwinPkgs;
  linux = common ++ linuxPkgs;
}
