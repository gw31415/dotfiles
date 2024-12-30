{
  description = "Custom wezterm-types";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.westerm-types-src = {
    url = "github:justinsgithub/wezterm-types";
    flake = false;
  };

  outputs = { self, ... }@inputs:
    let
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
      version = builtins.substring 0 8 lastModifiedDate;
    in
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import inputs.nixpkgs { inherit system; };
        wezterm-types-src = inputs.westerm-types-src;
      in
      {
        packages = inputs.flake-utils.lib.flattenTree rec{
          wezterm-types = pkgs.stdenvNoCC.mkDerivation {
            name = "wezterm-types-${version}";
            src = wezterm-types-src;
            installPhase = ''
              mkdir -p $out
              cp -r $src/types $src/.luarc.json $out/
              cp ${./src}/*.lua $out/
            '';
          };
          default = wezterm-types;
        };
      }
    );
}
