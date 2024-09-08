{
  description = "dotfiles and configurations for ama";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, nix-homebrew, ... }:
    let
      env = import ./env.nix;
      pkgs = import nixpkgs {
        system = env.system;
        config.allowUnfree = true;
      };
      dot-cli = pkgs.writeShellScriptBin "dot" ''exec ${pkgs.deno}/bin/deno run -qA --no-config ${(./dot/index.ts)} "$@"'';
    in
    {
      ########################################
      # Home manager configuration
      ########################################
      homeConfigurations.${env.username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ({ config, ... }: import ./home.nix { inherit config pkgs env dot-cli; })
        ];
      };

      ########################################
      # Darwin configuration with nix-homebrew
      ########################################
      darwinConfigurations."${env.hostname}" = nix-darwin.lib.darwinSystem {
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
      # Package sets
      ########################################
      packages.${env.system} = {
        # https://github.com/NixOS/nixpkgs/blob/808125fff694e4eb4c73952d501e975778ffdacd/pkgs/build-support/trivial-builders.nix#L238-L250
        default = dot-cli;

        # Note: These are used by dot-cli
        home-manager = home-manager.defaultPackage.${env.system};
        nix-darwin = nix-darwin.packages.${env.system}.default;
      };
    };
}
