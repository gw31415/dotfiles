{
  description = "dotfiles and configurations for ama";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.*.tar.gz";
    flake-utils.url = "https://flakehub.com/f/numtide/flake-utils/0.*.tar.gz";
    home-manager = {
      url = "github:nix-community/home-manager";
      # url = "https://flakehub.com/f/nix-community/home-manager/0.*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-darwin.follows = "nix-darwin";
      inputs.flake-utils.follows = "flake-utils";
    };
    wezterm-types = {
      url = "path:./wezterm-types";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, nix-darwin, nix-homebrew, wezterm-types, ... }:
    let
      env = import ./env.nix;
    in
    flake-utils.lib.eachDefaultSystem
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          dot-cli = pkgs.writeShellScriptBin "dot" ''exec ${pkgs.deno}/bin/deno run -qA --no-config ${./dot/index.ts} "$@"'';
        in
        {
          ########################################
          # Package sets
          ########################################
          packages = {
            home-manager = home-manager.defaultPackage.${system};
            nix-darwin = nix-darwin.packages.${system}.default;
            dot-cli = dot-cli;

            ########################################
            # Darwin configuration with nix-homebrew
            ########################################
            darwinConfigurations.${env.hostname} = nix-darwin.lib.darwinSystem
              {
                modules = [
                  ({ pkgs, ... }: import ./darwin.nix { inherit pkgs env; flake = self; })
                  (nix-homebrew.darwinModules.nix-homebrew {
                    lib = nix-darwin.lib;
                    nix-homebrew = {
                      enable = true;
                      enableRosetta = true;
                      user = env.username;
                      autoMigrate = true;
                    };
                  })
                ];
              };
            ########################################
            # Home manager configuration
            ########################################
            homeConfigurations.${env.username} = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                ({ config, ... }: import ./home.nix {
                  inherit config pkgs env;
                  dot-cli = self.packages.${system}.dot-cli;
                  wezterm-types = wezterm-types.packages.${system}.default;
                })
              ];
            };
            default = dot-cli;
          };
          apps = rec {
            dot-app = flake-utils.lib.mkApp { drv = self.packages.${system}.dot-cli; };
            default = dot-app;
          };
        }
      );
}
