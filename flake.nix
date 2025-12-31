{
  description = "dotfiles and configurations for ama";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    dot = {
      url = "github:gw31415/dot-cli";
      inputs = {
        nixpkgs.follows = "nixpkgs-stable";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      env = import ./env.nix;
    in
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        pkgs-stable = import inputs.nixpkgs-stable {
          inherit system;
          config.allowUnfree = true;
        };
        ctx = inputs // {
          inherit
            pkgs
            pkgs-stable
            system;
            dot = inputs.dot.packages.${system}.default;
        };
        overlays = [
          inputs.neovim-nightly-overlay.overlays.default
        ];
      in
      {
        ########################################
        # Package sets
        ########################################
        packages = {
          nix-darwin = ctx.nix-darwin.packages.${system}.default;

          ########################################
          # Darwin configuration with nix-homebrew
          ########################################
          darwinConfigurations.${env.hostname} = ctx.nix-darwin.lib.darwinSystem {
            modules = [
              ({ pkgs, ... }: import ./darwin.nix { inherit ctx; })
              (ctx.nix-homebrew.darwinModules.nix-homebrew {
                lib = ctx.nix-darwin.lib;
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
          homeConfigurations.${env.username} = ctx.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              (
                { config, ... }:
                import ./home.nix {
                  inherit config ctx;
                }
              )
              { nixpkgs.overlays = overlays; }
            ];
          };
          default = ctx.dot;
        };
        apps = rec {
          dot-app = ctx.flake-utils.lib.mkApp { drv = ctx.dot; };
          default = dot-app;
        };
      }
    );
}
