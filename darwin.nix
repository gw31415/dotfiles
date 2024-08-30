{ env, ... }: {
  ########################################
  # Requires for nix-darwin to work
  ########################################
  system.stateVersion = 4;
  nixpkgs.hostPlatform = env.system;
  nix = {
    # To keep-enabled experimental features after installation, since nix is managed by nix-darwin.
    settings.experimental-features = "nix-command flakes";
    # Auto upgrade nix package and the daemon service.
    # If you are in a multi-user environment, this is a must to avoid conflicts.
    useDaemon = true;
  };

  ########################################
  # Configuration for macOS system
  ########################################
  system.defaults = {
    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
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
}
