{ ctx }:
let
  pkgs = ctx.pkgs;
  pkgs-stable = ctx.pkgs-stable;
  sources = import ../../_sources/generated.nix {
    inherit (pkgs)
      dockerTools
      fetchFromGitHub
      fetchgit
      fetchurl
      ;
  };

  uniMacos = pkgs-stable.stdenvNoCC.mkDerivation {
    pname = "uni-macos";
    inherit (sources.uni-macos) version src;
    nativeBuildInputs = [ pkgs-stable.undmg ];
    unpackPhase = ''undmg "$src"'';
    installPhase = ''
      mkdir -p "$out/Applications"
      cp -R *.app "$out/Applications/"
    '';
  };
in
rec {
  inherit sources;

  commonCli = with pkgs-stable; [
    # LSPs
    pkgs.basedpyright
    gopls

    # CLI tools
    aria2
    asciinema
    bat
    bindfs
    deno
    # nixpkgs-stable の direnv 2.37.1 は Darwin で cgo 無効のまま
    # external link を要求してビルドに失敗するため、unstable 側を使う。
    pkgs.direnv
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
    nix-prefetch-docker
    nixfmt-rfc-style
    pkgs.nvfetcher
    p7zip
    pandoc
    poppler-utils
    ripgrep
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
  ];

  commonDev = with pkgs-stable; [
    ctx.rsplug
    sccache
    tree-sitter
    typst
  ];

  desktopExtras = with pkgs-stable; [
    ctx.dot
    rustup
  ];

  linuxDesktopApps = with pkgs-stable; [
    pkgs.brave
    pkgs.codex
    pkgs.mise
    pkgs.wezterm
    gnupg
    nodejs
  ];

  linuxContainerDev = with pkgs-stable; [
    cargo
    gnupg
    mise
    nodejs
    pkg-config
    rustc
    stdenv.cc
    pkgs.fish
  ];

  darwinNixPackages = with pkgs-stable; [
    cocoapods
    pkgs.container
    pkgs.alt-tab-macos
    uniMacos
  ];

  forTarget =
    target:
    if target == "darwin" then
      commonCli ++ commonDev ++ desktopExtras ++ darwinNixPackages
    else if target == "linux-desktop" then
      commonCli ++ commonDev ++ desktopExtras ++ linuxDesktopApps
    else if target == "linux-container" then
      commonCli ++ commonDev ++ linuxContainerDev
    else
      throw "unsupported package target: ${target}";
}
