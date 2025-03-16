{
  description = "dotfiles and configurations for ama";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.*.tar.gz";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";

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
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-darwin.follows = "nix-darwin";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dpp-vim = {
      url = "github:Shougo/dpp.vim";
      flake = false;
    };
    dpp-ext-installer = {
      url = "github:Shougo/dpp-ext-installer";
      flake = false;
    };
    dpp-ext-lazy = {
      url = "github:Shougo/dpp-ext-lazy";
      flake = false;
    };
    dpp-ext-toml = {
      url = "github:Shougo/dpp-ext-toml";
      flake = false;
    };
    dpp-protocol-git = {
      url = "github:Shougo/dpp-protocol-git";
      flake = false;
    };
  };

  outputs = { self, ... }@inputs:
    let
      env = import ./env.nix;
    in
    inputs.flake-utils.lib.eachDefaultSystem
      (
        system:
        let
          pkgs = import inputs.nixpkgs
            {
              inherit system;
              config.allowUnfree = true;
            };
          ctx = inputs // {
            pkgs = pkgs;
            pkgs-stable = import ctx.nixpkgs-stable
              {
                inherit system;
                config.allowUnfree = true;
              };
            dot = import ./dot/default.nix { inherit pkgs; };
            system = system;
          };
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
            darwinConfigurations.${env.hostname} = ctx.nix-darwin.lib.darwinSystem
              {
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
                ({ config, ... }: import ./home.nix {
                  inherit config ctx;
                })
                ctx.nixvim.homeManagerModules.nixvim
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
