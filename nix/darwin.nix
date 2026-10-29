# nix-darwin: root 権限のシステム設定・フォント・Nix 由来のパッケージだけを持つ薄い wrapper。
# user-level (symlink / shell / 開発ツール / host package / defaults / LaunchAgent) は
# mise bootstrap (config.macos.toml) が正。
{ pkgs, ... }:
let
  env = import ./env.nix;
in
{
  ########################################
  # Requires for nix-darwin to work
  ########################################
  system.stateVersion = 4;
  system.primaryUser = env.username;
  nixpkgs.hostPlatform = "aarch64-darwin";

  # REQUIRED: To keep-enabled experimental features after installation, since nix is managed by nix-darwin.
  nix.settings = {
    experimental-features = "nix-command flakes";
    trusted-users = [
      "root"
      "${env.username}"
    ];
  };

  # REQUIRED: Because this dotfiles is intended for a nix-darwin multi-user environment.
  nix.package = pkgs.nix;

  ########################################
  # Fonts (Nix 管理に残す)
  ########################################
  fonts.packages = with pkgs; [
    hackgen-nf-font
    ipaexfont
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    source-han-sans
    source-han-serif
    twemoji-color-font
  ];

  ########################################
  # Nix 専用ツール
  ########################################
  environment.systemPackages = with pkgs; [
    comma
    # kakehashi/nil が Nix ファイルの整形に呼び出す Nix 専用 formatter。
    nixfmt
    # Linux の `.#shared` と同じ nixpkgs から入れて、暗号化・bind mount を揃える。
    # mise / Homebrew に macOS 向けの配布が無い。
    bindfs
    gocryptfs
  ];

  ########################################
  # Tailscale (system daemon + CLI + MagicDNS resolver)
  ########################################
  # 初回のみ `sudo tailscale up` で認証が必要。
  services.tailscale.enable = true;

  ########################################
  # sudo の Touch ID (root 権限の /etc/pam.d)
  ########################################
  security.pam.services.sudo_local = {
    enable = true;
    reattach = true;
    touchIdAuth = true;
    watchIdAuth = true;
  };

  ########################################
  # System activation
  ########################################
  system.activationScripts.extraActivation.text = ''
    # 以前は Spotlight の index を止めていたが、mas がインストール済みアプリの判別に
    # index を使うため有効に戻す (止めたままだと bootstrap のたびに再導入を試みる)。
    /usr/bin/mdutil -a -i on

    softwareupdate --all --download --background
  '';
}
