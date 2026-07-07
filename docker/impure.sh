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

# rustup と mise で nvim/ツール群を整える。
# - `mise install` はフルツールセットのベストエフォート導入。一部ツールはコンテナ環境では
#   原理上インストール不可（該当 arch のバイナリ不在、システムライブラリ不足）だが、
#   それは nvim/シェルの核心機能に影響しないため、失敗をログに残しつつ継続する。
#   ※ これは nvim 破壊を隠していた旧 `|| true` とは異なる。失敗は --verbose で可視化される。
# - `rsplug -i`（nvim 必須）は厳格に実行し、失敗すればビルドを落とす。
# rsplug の CLI は `rsplug -i <glob>`（install はサブコマンドではなく -i/--install フラグ）。
#
# rsplug は `mise exec` 経由ではなくバイナリを直接実行する。`mise exec` は全ツールの環境
# 啓動を試み、コンテナで導入不可なツールがあると失敗して rsplug まで巻き込むため、mise の
# 環境啓動から切り離す（rsplug 自体は git/ネットワークのみで単独動作する）。
(
  rustup default stable
  mise install --verbose || echo "impure.sh: WARNING some optional mise tools failed to install (see verbose log above); nvim/core tooling is unaffected"
  rsplug_bin="$(find "$HOME/.local/share/mise/installs/github-gw31415-rsplug-nvim" -name rsplug -type f 2>/dev/null | head -1)"
  if [ -z "$rsplug_bin" ]; then
    echo "impure.sh: ERROR rsplug binary not found after mise install" >&2
    exit 1
  fi
  "$rsplug_bin" -i "$dotfiles_dir/nvim/rsplug/*.toml"
) &
pid_b=$!

status=0

wait "$pid_a" || status=1
wait "$pid_b" || status=1

exit "$status"
