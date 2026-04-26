{ lib, ... }:
{
  home.username = lib.mkForce "root";
  home.homeDirectory = lib.mkForce "/root";
  manual.manpages.enable = false;
}
