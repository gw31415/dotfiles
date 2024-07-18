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
      username = env.username;
      homeManagerPath = env.homeManagerPath;
      home = { config, pkgs, target_path, ... }:
        import ./home.nix {
          inherit config pkgs username homeManagerPath;
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
