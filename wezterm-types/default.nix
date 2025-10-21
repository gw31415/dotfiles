{
  pkgs ? import <nixpkgs> { system = builtins.currentSystem; },
}:
pkgs.stdenvNoCC.mkDerivation {
  name = "wezterm-types";
  src = pkgs.fetchFromGitHub {
    owner = "justinsgithub";
    repo = "wezterm-types";
    rev = "1518752906ba3fac0060d9efab6e4d3ec15d4b5a";
    hash = "sha256-dSxsrgrapUezQIGhNp/Ikc0kISfIdrlUZxUBdsLVe3A=";
  };
  installPhase = ''
    mkdir -p $out
    cp -r $src/lua/wezterm/types $src/.luarc.json $out/
    cp ${./src}/*.lua $out/
  '';
}
