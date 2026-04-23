{ lib, ... }:
let
  env = import ../../../env.nix;
in
{
  home.homeDirectory = lib.mkForce "/home/${env.username}";
  manual.manpages.enable = false;
}
