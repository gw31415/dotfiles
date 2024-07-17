{
  description = "Darwin configuration of ama";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      env = builtins.fromJSON (builtins.readFile ./env.json);
      system = env.system;
    in
    {
      homeConfigurations.ama = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { inherit system; };
        modules = [ ./home.nix ];
      };
      packages.${system}.default = home-manager.defaultPackage.${system};
    };
}
