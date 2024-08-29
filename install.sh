#!/usr/bin/env bash
set -euC
# Nix is required to be installed
if [ -z "$(command -v nix)" ]; then
  echo "Nix is not installed. Please install Nix first."
  exit 1
fi

# Get Nix configuration and check experimental-features
FEATURES=$(nix show-config | grep experimental-features | awk -F '=' '{print $2}')
if [[ -z "$FEATURES" ]]; then
  echo "experimental-features is not set."
  exit 1
else
  if [[ "$FEATURES" != *"nix-command"* || "$FEATURES" != *"flakes"* ]]; then
    echo "nix-command and/or flakes are not set."
    exit 1
  fi
fi

# Obtaining various variables
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
TARGET_PATH=$XDG_CONFIG_HOME/home-manager

# Cloning the dotfiles
if [ -d $TARGET_PATH ]; then
  echo "The target path $TARGET_PATH is already exist. Please remove it first."
  exit 1
fi
mkdir -p $XDG_CONFIG_HOME
nix run nixpkgs#git -- clone https://github.com/gw31415/dotfiles $TARGET_PATH

# Installing home-manager and initial sync
nix run nixpkgs#home-manager -- switch
