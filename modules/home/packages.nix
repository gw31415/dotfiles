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
    nix-prefetch-docker
    nixfmt-rfc-style
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

    # Development tools
    ctx.dot
    ctx.rsplug
    sccache
    tree-sitter
    rustup
  ];

  darwinPkgs = with pkgs-stable; [
    pkgs.alt-tab-macos
    cocoapods
    container
    uniMacos
  ];

  # TODO: 以下のパッケージを整理する
  linuxPkgs = with pkgs; [
    # macOSでは darwin.nix で有効化する
    fish


    # macOSでは brew でインストールする
    codex
    gnupg
    mise
  ];

  linuxDesktopPkgs = with pkgs; [
    brave
    ghostty
  ];

  forTarget =
    target:
    if target == "darwin" then
      common ++ darwinPkgs
    else if target == "linux-container" then
      common ++ linuxPkgs
    else if target == "linux-desktop" then
      common ++ linuxPkgs ++ linuxDesktopPkgs
    else
      throw "unsupported package target: ${target}";
}
