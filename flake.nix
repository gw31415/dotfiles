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
      pkgs = import nixpkgs { system = env.system; };
    in
    {
      homeConfigurations.${env.username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ({ config, ... }: import ./home.nix { inherit config pkgs env; })
        ];
      };
      packages.${env.system}.default = home-manager.defaultPackage.${env.system};
    };
}
