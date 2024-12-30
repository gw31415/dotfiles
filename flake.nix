{
  description = "dotfiles and configurations for ama";

  inputs = {
    # nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.*.tar.gz";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
      inputs.flake-utils.follows = "flake-utils";
    };
    wezterm-types = {
      url = "path:wezterm-types";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
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
          pkgs = import inputs.nixpkgs {
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
            home-manager = pkgs.home-manager;
            nix-darwin = inputs.nix-darwin.packages.${system}.default;
            dot-cli = dot-cli;

            ########################################
            # Darwin configuration with nix-homebrew
            ########################################
            darwinConfigurations.${env.hostname} = inputs.nix-darwin.lib.darwinSystem
              {
                modules = [
                  ({ pkgs, ... }: import ./darwin.nix { inherit pkgs system; })
                  (inputs.nix-homebrew.darwinModules.nix-homebrew {
                    lib = inputs.nix-darwin.lib;
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
            homeConfigurations.${env.username} = inputs.home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                ({ config, ... }: import ./home.nix {
                  inherit config pkgs env;
                  dot-cli = self.packages.${system}.dot-cli;
                  wezterm-types = inputs.wezterm-types.packages.${system}.default;
                })
              ];
            };
            default = dot-cli;
          };
          apps = rec {
            dot-app = inputs.flake-utils.lib.mkApp { drv = self.packages.${system}.dot-cli; };
            default = dot-app;
          };
        }
      );
}
