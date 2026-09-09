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

_is_nix_store_link() {
  case "$(_abspath "$1")" in
    /nix/store/*) return 0 ;;
    *) return 1 ;;
  esac
}

# 旧 Home Manager は、このスクリプトが現在所有する destination を
# /nix/store 配下へ symlink していた。symlink 自体だけを外すため、
# store の内容やユーザー作成ファイルは削除しない。
_migrate_nix_store_link() {
  local dest="$1"
  rm "$dest"
  echo "migrate: removed legacy Nix link $dest"
}

link() {
  local src="$REPO/$1" dest="$HOME/$2"
  if [ -L "$dest" ]; then
    if [ "$(_abspath "$dest")" = "$src" ]; then
      return 0
    fi
    if _is_nix_store_link "$dest"; then
      _migrate_nix_store_link "$dest"
    else
      echo "SKIP (link mismatch): $dest -> $(readlink "$dest") (want $src)"
      CONFLICTS=$((CONFLICTS + 1))
      return 0
    fi
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

# pez はここへ plugin ファイルを展開するため、fish の3ディレクトリは
# 実ディレクトリである必要がある。旧 Home Manager の Nix-store symlink と、
# 以前の repo ディレクトリ symlink だけを安全に移行する。
ensure_real_fish_directory() {
  local relative legacy_source dest
  relative="$1"
  legacy_source="$2"
  dest="$HOME/$relative"
  if [ -L "$dest" ]; then
    if _is_nix_store_link "$dest" || [ "$(_abspath "$dest")" = "$REPO/$legacy_source" ]; then
      rm "$dest"
      mkdir -p "$dest"
      echo "migrate: created real directory $dest"
      return 0
    fi
    echo "SKIP (directory link mismatch): $dest -> $(readlink "$dest")" >&2
    CONFLICTS=$((CONFLICTS + 1))
    return 1
  fi
  if [ -e "$dest" ] && [ ! -d "$dest" ]; then
    echo "SKIP (not a directory): $dest" >&2
    CONFLICTS=$((CONFLICTS + 1))
    return 1
  fi
  mkdir -p "$dest"
}

# Home Manager が生成した fish の起動ファイルと plugin hook は、新しい
# conf.d/pez と二重に読み込まれる。Nix store を向く legacy link だけを外す。
migrate_legacy_fish_file() {
  local dest="$1"
  if [ -L "$dest" ] && _is_nix_store_link "$dest"; then
    _migrate_nix_store_link "$dest"
  fi
}

# ディレクトリ配置
# wezterm は廃止済み。kakehashi は Neovim の LSP bridge のユーザ設定。
for d in tunnel-client freeze ghostty lazygit commitgen audiorouter herdr kakehashi mise; do
  link "config/$d" ".config/$d"
done
link "config/nvim_lua" ".config/nvim/lua"
link "config/nvim_after" ".config/nvim/after"

# ~/.config/git は既存のユーザー設定を収容できる実ディレクトリとして残し、
# このリポジトリが所有する3ファイルだけを個別に配置する。
for f in "$REPO"/config/git/*; do
  link "config/git/$(basename -- "$f")" ".config/git/$(basename -- "$f")"
done

# ファイル配置
link "config/nvim/init.lua" ".config/nvim/init.lua"
link "files/latexmkrc" ".latexmkrc"
link "files/SKK-JISYO.L" ".skk/SKK-JISYO.L"
link "config/fd/ignore" ".config/fd/ignore"
link "config/fish/pez.toml" ".config/fish/pez.toml"
link "config/fish/pez-lock.toml" ".config/fish/pez-lock.toml"

# fish 配下はファイル単位で配置する。
# (pez が plugin ファイルをコピーする先のため、ディレクトリ symlink は不可)
if ensure_real_fish_directory ".config/fish/conf.d" "config/fish/conf.d" \
  && ensure_real_fish_directory ".config/fish/functions" "config/fish_functions" \
  && ensure_real_fish_directory ".config/fish/completions" "config/fish_completions"; then
  migrate_legacy_fish_file "$HOME/.config/fish/config.fish"
  for f in "$HOME"/.config/fish/conf.d/plugin-*.fish; do
    migrate_legacy_fish_file "$f"
  done
  for f in "$REPO"/config/fish/conf.d/*.fish; do
    link "config/fish/conf.d/$(basename -- "$f")" ".config/fish/conf.d/$(basename -- "$f")"
  done
  for f in "$REPO"/config/fish_functions/*.fish; do
    link "config/fish_functions/$(basename -- "$f")" ".config/fish/functions/$(basename -- "$f")"
  done
  for f in "$REPO"/config/fish_completions/*.fish; do
    link "config/fish_completions/$(basename -- "$f")" ".config/fish/completions/$(basename -- "$f")"
  done
fi

if [ "$CONFLICTS" -gt 0 ]; then
  echo "$CONFLICTS conflict(s): resolve manually and re-run" >&2
  exit 1
fi
echo "link: done ($REPO)"
