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
  # reset --hard は untracked ファイルを削除しない。イメージに bake-in された旧ファイル
  # （例: main で fern.toml→filer.toml にリネームされた後の旧 fern.toml）が残ると rsplug が
  # duplicate node で失敗するため、main の tracked ツリー以外を掃除してクリーンな checkout にする。
  git -C "$dotfiles_dir" clean -fdx
) &
pid_a=$!

# rustup と mise でツール群を整える。
# - `mise install` はフルツールセットのベストエフォート導入。一部ツールはコンテナ環境では
#   原理上インストール不可（該当 arch のバイナリ不在、システムライブラリ不足）であり、
#   失敗をログに残しつつ継続する（nvim 破壊を隠していた旧 `|| true` とは異なる）。
#   なお mise の prebuild ツールは nix コンテナの FHS が無いと起動できないものがある。
# - `rsplug -i`（nvim 必須）は nix パッケージ（~/.nix-profile/bin）を直接実行し、厳格に。
#   mise の prebuild は動的リンカが解決せず起動不能なため、nix ビルド版を使う。
(
  rustup default stable
  mise install --verbose || echo "impure.sh: WARNING some optional mise tools failed to install (see verbose log above); nvim/core tooling is unaffected"
  rsplug -i "$dotfiles_dir/nvim/rsplug/*.toml"
) &
pid_b=$!

status=0

wait "$pid_a" || status=1
wait "$pid_b" || status=1

exit "$status"
