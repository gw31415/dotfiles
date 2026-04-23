#!/usr/bin/env bash
set -euo pipefail

target_repo="${XDG_CONFIG_HOME}/home-manager"
branch="${HOME_MANAGER_GIT_BRANCH:-main}"

mkdir -p "$(dirname "$target_repo")"
rm -rf "$target_repo"
cp -a /work "$target_repo"
chmod -R u+w "$target_repo"

git config --global --add safe.directory "$target_repo"
git -C "$target_repo" fetch --depth=1 origin "$branch"
git -C "$target_repo" checkout -B "$branch" FETCH_HEAD
git -C "$target_repo" pull --ff-only origin "$branch"

cd "$HOME"
"${HOME_MANAGER_ACTIVATE:?HOME_MANAGER_ACTIVATE must be set}"
set +u
. "${HOME_MANAGER_HOME_PATH:?HOME_MANAGER_HOME_PATH must be set}/etc/profile.d/hm-session-vars.sh"
set -u

nix-collect-garbage -d

mise trust "$XDG_CONFIG_HOME/mise/config.toml"
mise i
rsplug -i "$RSPLUG_CONFIG_FILES"
