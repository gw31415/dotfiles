#!/usr/bin/env bash
#MISE description="Update tools, plugins and package layers"
set -euo pipefail

_SRC="${BASH_SOURCE[0]}"
while [ -L "$_SRC" ]; do
  _DIR="$(cd -P -- "$(dirname -- "$_SRC")" && pwd)"
  _SRC="$(readlink "$_SRC")"
  case "$_SRC" in /*) ;; *) _SRC="$_DIR/$_SRC" ;; esac
done
REPO="$(cd -P -- "$(dirname -- "$_SRC")/../../.." && pwd)"

OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
  brew bundle --file="$REPO/Brewfile"
elif [ "$OS" = "Linux" ] && command -v nix >/dev/null 2>&1; then
  nix profile remove dotfiles-shared 2>/dev/null || true
  nix profile install "$REPO#shared"
fi

mise up --bump
pez upgrade
pez doctor
echo "update: done"
