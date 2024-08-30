{
  description = "Home manager configuration of ama";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      env = import ./env.nix;
    in
    {
      homeConfigurations.${env.username} = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = env.system; };
        modules = [
          ({ config, pkgs, opts, ... }: import ./home.nix { inherit config pkgs env; })
        ];
      };
      packages.${env.system}.default = home-manager.defaultPackage.${env.system};
    };
}
