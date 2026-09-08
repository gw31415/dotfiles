# macOS の GUI と brew 導入基盤の真実。darwin.nix から import される。
# 開発 CLI はここに置かない (mise が正)。
{
  homebrew = {
    enable = true;
    onActivation.autoUpdate = false;
    taps = [
      "homebrew/bundle"
      "homebrew/services"
      "jorgelbg/tap"
      "arto-app/tap"
      "anomalyco/tap"
      "macos-fuse-t/homebrew-cask"
      "steipete/tap"
    ];
    brews = [
      "mise"
      "cocoapods"
      "openssl@3"
      "gettext"
      "gnupg"
      "libgpg-error"
      "mas"
      "pinentry-mac"
      "pkgconf"
      "xcode-build-server"
      "jorgelbg/tap/pinentry-touchid"
      "steipete/tap/codexbar"
    ];
    # メモ： MTG補助用AI - Cluely はCaskなし (https://cluely.com/)
    casks = [
      "arto"
      # "affinity"
      "anki"
      # "brave-browser"
      "blackhole-2ch"
      # "claude"
      "claude-code"
      "codex"
      "codex-app"
      "discord"
      # "figma"
      "gnucash"
      "iloader"
      "keybase"
      "macfuse"
      "macskk"
      # "macshot" # Vorssaint
      # "microsoft-teams"
      # "music-decoy" # Vorssaint
      "musicbrainz-picard"
      # "opencode-desktop"
      "open-design"
      "puremac"
      "slack"
      "smoothcsv"
      "thaw"
      "google-chrome"
      "ghostty"
      "vorssaint"
      "waku"
      # "android-studio"
      # "container"
      # "cursor"
      # "devtoys"
      # "gather"
      # "keepassxc"
      # "obs"
      "obsidian"
      # "piphero"
      # "postman"
      # "secretive"
      "zoom"

      # Home Manager GUI apps
      # "microsoft-auto-update"
      # "orbstack"
    ];
    masApps = {
      "1Blocker" = 1365531024;
      "Amphetamine" = 937984704;
      # "Goodnotes" = 1444383602;
      "Keynote" = 409183694;
      "LINE" = 539883307;
      "Logic Pro" = 634148309;
      "Ice Cubes for Mastodon" = 6444915884;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      # "RunCat" = 1429033973;
      "Xcode" = 497799835;
      "タイピスト" = 415166115;
      "宛名印刷" = 1598123076;

      # Pro Apps
      # "Compressor" = 424390742;
      # "Final Cut Pro" = 424389933;
      # "MainStage" = 634159523;
      # "Motion" = 434290957;
    };
  };
}
