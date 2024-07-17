#!/usr/bin/env bash
if [ -z "$(command -v nix)" ]; then
  echo "Nix is not installed. Please install Nix first."
  exit 1
fi
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
TARGET_PATH=$XDG_CONFIG_HOME/home-manager
SYSTEM=$(nix eval --raw --expr 'builtins.currentSystem' --impure)
if [ -d $TARGET_PATH ]; then
  echo "The target path $TARGET_PATH is already exist. Please remove it first."
  exit 1
fi
mkdir -p $XDG_CONFIG_HOME
nix run nixpkgs#git -- clone https://github.com/gw31415/dotfiles $TARGET_PATH
echo '{ "system": "'$SYSTEM'" }' > $TARGET_PATH/env.json
nix run nixpkgs#home-manager -- switch
