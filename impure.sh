#!/usr/bin/env sh
set -eu

. /etc/profile.d/*.sh

/activate

dotfiles_dir="$HOME/.config/home-manager"

(
  git init "$dotfiles_dir"
  git -C "$dotfiles_dir" remote add origin https://github.com/gw31415/dotfiles
  git -C "$dotfiles_dir" fetch
  git -C "$dotfiles_dir" branch main origin/main
  git -C "$dotfiles_dir" reset
) &
pid_a=$!

(
  rustup default stable
  rsplug -i "$dotfiles_dir/nvim/rsplug/*.toml"
) &
pid_b=$!

(
  mise i
) &
pid_c=$!

status=0

wait "$pid_a" || status=1
wait "$pid_b" || status=1
wait "$pid_c" || status=1

exit "$status"
