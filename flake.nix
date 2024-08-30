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
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, ... }:
    let
      env = import ./env.nix;
      pkgs = import nixpkgs { system = env.system; };
    in
    {
      ########################################
      # Home manager configuration
      ########################################
      homeConfigurations.${env.username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ({ config, ... }: import ./home.nix { inherit config pkgs env; })
        ];
      };

      ########################################
      # Darwin configuration
      ########################################
      darwinConfigurations."${env.hostname}" = nix-darwin.lib.darwinSystem {
        modules = [
          ({ pkgs, ... }: import ./darwin.nix { inherit pkgs env; flake = self; })
        ];
      };

      ########################################
      # Package sets
      ########################################
      packages.${env.system} = {
        # https://github.com/NixOS/nixpkgs/blob/808125fff694e4eb4c73952d501e975778ffdacd/pkgs/build-support/trivial-builders.nix#L238-L250
        default = pkgs.writeShellScriptBin "default" (builtins.readFile ./install.sh);

        # Note: These are used by ./install.sh.
        home-manager = home-manager.defaultPackage.${env.system};
        nix-darwin = nix-darwin.packages.${env.system}.default;
      };
    };
}
