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
      system = "aarch64-darwin";
      username = "ama";
      home = { config, pkgs, homeManagerPath, ... }:
        import ./home.nix {
          inherit config pkgs username; homeManagerPath = "/Users/${username}/.config/home-manager";
        };
    in
    {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { inherit system; };
        modules = [ home ];
      };
      packages.${system}.default = home-manager.defaultPackage.${system};
    };
}
