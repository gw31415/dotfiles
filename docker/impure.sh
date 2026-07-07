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
  git -C "$dotfiles_dir" reset --hard main
) &
pid_a=$!

# rsplug は mise 管理ツール（mise config.toml で github:gw31415/rsplug.nvim として定義）。
# rustup と mise install を先に完了させ、その後 mise exec 経由で rsplug を実行する。
# rsplug の CLI は `rsplug -i <glob>`（install はサブコマンドではなく -i/--install フラグ）。
(
  rustup default stable
  mise install --verbose
  mise exec -- rsplug -i "$dotfiles_dir/nvim/rsplug/*.toml"
) &
pid_b=$!

status=0

wait "$pid_a" || status=1
wait "$pid_b" || status=1

exit "$status"
