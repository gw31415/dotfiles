{ ctx, ... }: {
  ########################################
  # Requires for nix-darwin to work
  ########################################
  system.stateVersion = 4;
  nixpkgs.hostPlatform = ctx.system;

  # REQUIRED: To keep-enabled experimental features after installation, since nix is managed by nix-darwin.
  nix.settings.experimental-features = "nix-command flakes";

  # REQUIRED: Because this dotfiles is intended for a nix-darwin multi-user environment.
  nix.package = ctx.pkgs.nix;

  # REQUIRED: Create /etc/fish that loads the nix-darwin environment.
  programs.fish.enable = true;

  ########################################
  # Configuration for macOS system
  ########################################
  system.defaults = {
    finder = {
      AppleShowAllExtensions = true;
      CreateDesktop = true;
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
      ShowStatusBar = false;
    };
    dock = {
      autohide = true;
      show-recents = false;
      tilesize = 50;
      magnification = true;
      largesize = 64;
      orientation = "bottom";
      launchanim = false;
    };
  };

  security.pam.services.sudo_local = {
    enable = true;
    reattach = true;
    touchIdAuth = true;
    watchIdAuth = true;
  };

  ########################################
  # Homebrew
  ########################################

  homebrew = {
    enable = true;
    onActivation.autoUpdate = true;
    taps = [
      "homebrew/bundle"
      "homebrew/cask-fonts"
      "homebrew/cask-versions"
      "homebrew/core"
      "homebrew/services"
      "jorgelbg/tap"
      "macos-fuse-t/homebrew-cask"
    ];
    brews = [
      "openssl@3"
      "gettext"
      "iconsur"
      "libgpg-error"
      "mas"
      "mise"
      "pinentry-mac"
      "pkgconf"
      "xcode-build-server"
      "jorgelbg/tap/pinentry-touchid"

      # because building Node.js in NixOS is slow
      "pnpm"
      "fish-lsp"
    ];
    casks = [
      "alt-tab"
      "android-studio"
      "anki"
      "battery"
      "brave-browser"
      "chatgpt"
      "devtoys"
      "discord"
      "figma"
      "gather"
      "gnucash"
      "inkscape"
      "keepassxc"
      "keybase"
      "macfuse"
      "macskk"
      "microsoft-auto-update"
      "microsoft-teams"
      "musicbrainz-picard"
      "obsidian"
      "orbstack"
      "piphero"
      "postman"
      "slack"
      "visual-studio-code"
      "vlc"
      "wezterm@nightly"
      "zoom"
    ];
    masApps = {
      "1Blocker" = 1365531024;
      "Amphetamine" = 937984704;
      "Compressor" = 424390742;
      "Final Cut Pro" = 424389933;
      "Goodnotes" = 1444383602;
      "Keynote" = 409183694;
      "LINE" = 539883307;
      "Logic Pro" = 634148309;
      "MainStage" = 634159523;
      "Mona" = 1659154653;
      "Motion" = 434290957;
      "Numbers" = 409203825;
      "OmniFocus" = 1542143627;
      "Pages" = 409201541;
      "RunCat" = 1429033973;
      "Shortcut Notch" = 6447055708;
      "Xcode" = 497799835;
      "タイピスト" = 415166115;
      "宛名印刷" = 1598123076;
    };
  };

  ########################################
  # Auto install software updates
  ########################################
  system.activationScripts.extraActivation.text = ''
    softwareupdate --all --download --background
  '';
}
