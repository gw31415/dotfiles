{ system, pkgs, ... }: {
  ########################################
  # Requires for nix-darwin to work
  ########################################
  system.stateVersion = 4;
  nixpkgs.hostPlatform = system;

  # REQUIRED: To keep-enabled experimental features after installation, since nix is managed by nix-darwin.
  nix.settings.experimental-features = "nix-command flakes";

  # REQUIRED: Because this dotfiles is intended for a nix-darwin multi-user environment.
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;

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

  ########################################
  # Auto install software updates
  ########################################
  system.activationScripts.extraActivation.text = ''
    softwareupdate --all --install
  '';
}
