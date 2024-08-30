{
  description = "My personal Nix flake of dotfiles and configurations";

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
      # Re-export home-manager flake output for convenience. It used by ./install.sh.
      packages.${env.system}.default = home-manager.defaultPackage.${env.system};

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
          ({ ... }: import ./darwin.nix { inherit pkgs env; flake = self; })
        ];
      };
      darwinPackages = self.darwinConfigurations."${env.hostname}".pkgs;
    };
}
