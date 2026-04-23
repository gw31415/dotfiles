{ ctx, target, ... }:
let
  targetModule =
    if target == "darwin" then
      ./modules/home/targets/darwin.nix
    else if target == "linux-container" then
      ./modules/home/targets/linux-container.nix
    else if target == "linux-desktop" then
      ./modules/home/targets/linux-desktop.nix
    else
      throw "unsupported home-manager target: ${target}";
in
{
  _module.args = {
    inherit ctx;
    inherit target;
  };

  imports = [
    ./modules/home/base.nix
    targetModule
  ];
}
