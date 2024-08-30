{ pkgs, flake, env, ... }: {
  environment.systemPackages = [
    pkgs.fish
    pkgs.home-manager
  ];
  programs.fish.enable = true;
  environment.shells = [
    pkgs.fish
  ];

  services.nix-daemon.enable = true;

  nix.settings.experimental-features = "nix-command flakes";
  system.defaults.finder = {
    AppleShowAllExtensions = true;
    FXEnableExtensionChangeWarning = false;
    ShowPathbar = true;
    ShowStatusBar = false;
  };
  system.defaults.dock = {
    autohide = true;
    show-recents = false;
    tilesize = 50;
    magnification = true;
    largesize = 64;
    orientation = "bottom";
    # mineffect = "scale";
    launchanim = false;
  };

  system.configurationRevision = flake.rev or flake.dirtyRev or null;

  system.stateVersion = 4;
  nixpkgs.hostPlatform = env.system;
}
