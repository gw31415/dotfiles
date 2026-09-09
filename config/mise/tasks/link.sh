#!/usr/bin/env bash
#MISE description="Symlink dotfiles (config/*, files/*) into $HOME"
# mise 経由 (`mise run link`) でも直接実行でも動作する。
set -euo pipefail

_SRC="${BASH_SOURCE[0]}"
while [ -L "$_SRC" ]; do
  _DIR="$(cd -P -- "$(dirname -- "$_SRC")" && pwd)"
  _SRC="$(readlink "$_SRC")"
  case "$_SRC" in /*) ;; *) _SRC="$_DIR/$_SRC" ;; esac
done
REPO="$(cd -P -- "$(dirname -- "$_SRC")/../../.." && pwd)"

CONFLICTS=0

_abspath() {
  if [ -L "$1" ]; then
    local t
    t="$(readlink "$1")"
    case "$t" in
      /*) printf '%s\n' "$t" ;;
      *) printf '%s\n' "$(cd -P -- "$(dirname -- "$1")" && pwd)/$t" ;;
    esac
  else
    printf '%s\n' "$1"
  fi
}

link() {
  local src="$REPO/$1" dest="$HOME/$2"
  if [ -L "$dest" ]; then
    if [ "$(_abspath "$dest")" = "$src" ]; then
      return 0
    fi
    echo "SKIP (link mismatch): $dest -> $(readlink "$dest") (want $src)"
    CONFLICTS=$((CONFLICTS + 1))
    return 0
  fi
  if [ -e "$dest" ]; then
    echo "SKIP (exists): $dest (hand over manually, then re-run)"
    CONFLICTS=$((CONFLICTS + 1))
    return 0
  fi
  mkdir -p -- "$(dirname -- "$dest")"
  ln -s "$src" "$dest"
  echo "link: $2"
}

# ディレクトリ配置
# wezterm は廃止済み。kakehashi は Neovim の LSP bridge のユーザ設定。
for d in tunnel-client freeze ghostty lazygit commitgen git audiorouter herdr kakehashi mise; do
  link "config/$d" ".config/$d"
done
link "config/nvim_lua" ".config/nvim/lua"
link "config/nvim_after" ".config/nvim/after"

# ファイル配置
link "config/nvim/init.lua" ".config/nvim/init.lua"
link "files/latexmkrc" ".latexmkrc"
link "files/SKK-JISYO.L" ".skk/SKK-JISYO.L"
link "config/fd/ignore" ".config/fd/ignore"
link "config/fish/pez.toml" ".config/fish/pez.toml"
link "config/fish/pez-lock.toml" ".config/fish/pez-lock.toml"

# fish 配下はファイル単位で配置する。
# (pez が plugin ファイルをコピーする先のため、ディレクトリ symlink は不可)
for f in "$REPO"/config/fish/conf.d/*.fish; do
  link "config/fish/conf.d/$(basename -- "$f")" ".config/fish/conf.d/$(basename -- "$f")"
done
for f in "$REPO"/config/fish_functions/*.fish; do
  link "config/fish_functions/$(basename -- "$f")" ".config/fish/functions/$(basename -- "$f")"
done
for f in "$REPO"/config/fish_completions/*.fish; do
  link "config/fish_completions/$(basename -- "$f")" ".config/fish/completions/$(basename -- "$f")"
done

if [ "$CONFLICTS" -gt 0 ]; then
  echo "$CONFLICTS conflict(s): resolve manually and re-run" >&2
  exit 1
fi
echo "link: done ($REPO)"
