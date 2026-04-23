#!/usr/bin/env bash
set -euo pipefail

workspace_source="${1:-${HOME_MANAGER_WORKTREE_SOURCE:-/work}}"
target_repo="${HOME:-/home/ama}/.config/home-manager"
target_parent="$(dirname "$target_repo")"
branch="${HOME_MANAGER_GIT_BRANCH:-main}"
activate_script="${HOME_MANAGER_ACTIVATE:?HOME_MANAGER_ACTIVATE must be set}"
bootstrap_tools="${HOME_MANAGER_BOOTSTRAP_TOOLS:-0}"
default_ca_bundle="${NIX_SSL_CERT_FILE:-/etc/ssl/certs/ca-bundle.crt}"
mise_config_file="${XDG_CONFIG_HOME:-${HOME:-/home/ama}/.config}/mise/config.toml"

if [ ! -d "$workspace_source/.git" ]; then
  echo "expected a git worktree at $workspace_source" >&2
  exit 1
fi

mkdir -p "$target_parent"
rm -rf "$target_repo"
cp -a "$workspace_source" "$target_repo"
chmod -R u+w "$target_repo"

if [ -f "$default_ca_bundle" ]; then
  export SSL_CERT_FILE="${SSL_CERT_FILE:-$default_ca_bundle}"
  export NIX_SSL_CERT_FILE="${NIX_SSL_CERT_FILE:-$default_ca_bundle}"
  export GIT_SSL_CAINFO="${GIT_SSL_CAINFO:-$default_ca_bundle}"
  export CURL_CA_BUNDLE="${CURL_CA_BUNDLE:-$default_ca_bundle}"
fi

git config --global --add safe.directory "$target_repo"
git -C "$target_repo" fetch --depth=1 origin "$branch"
git -C "$target_repo" checkout -B "$branch" FETCH_HEAD
git -C "$target_repo" pull --ff-only origin "$branch"

cd "${HOME:-/home/ama}"
"$activate_script"

cd "$target_repo"
if [ "$bootstrap_tools" != "1" ]; then
  exit 0
fi
if [ -f "$mise_config_file" ]; then
  mise trust "$mise_config_file"
fi
mise i
rsplug -i
