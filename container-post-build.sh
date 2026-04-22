#!/usr/bin/env bash
set -euo pipefail

workspace_source="${1:-${HOME_MANAGER_WORKTREE_SOURCE:-/work}}"
target_repo="${HOME:-/home/ama}/.config/home-manager"
target_parent="$(dirname "$target_repo")"
branch="${HOME_MANAGER_GIT_BRANCH:-main}"

if [ ! -d "$workspace_source/.git" ]; then
  echo "expected a git worktree at $workspace_source" >&2
  exit 1
fi

mkdir -p "$target_parent"
rm -rf "$target_repo"
cp -a "$workspace_source" "$target_repo"
chmod -R u+w "$target_repo"

git config --global --add safe.directory "$target_repo"
git -C "$target_repo" fetch --depth=1 origin "$branch"
git -C "$target_repo" checkout -B "$branch" FETCH_HEAD
git -C "$target_repo" pull --ff-only origin "$branch"

cd "$target_repo"
mise i
rsplug -i
