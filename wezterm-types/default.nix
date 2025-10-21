{
  pkgs ? import <nixpkgs> { system = builtins.currentSystem; },
}:
pkgs.stdenvNoCC.mkDerivation {
  name = "wezterm-types";
  src = pkgs.fetchFromGitHub {
    owner = "DrKJeff16";
    repo = "wezterm-types";
    rev = "8fbb880a61480460a7a073a04a365fa6c2b16410";
    hash = "sha256-JL216U0S0AG8eHQ6/LPqorjeB2rL2BkcZcrl88vstvQ=";
  };
  installPhase = ''
    mkdir -p $out
    cp -r $src/lua/wezterm/types $src/.luarc.json $out/
    cp ${./src}/*.lua $out/
  '';
}
