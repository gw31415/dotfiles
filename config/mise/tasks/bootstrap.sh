#!/usr/bin/env bash
#MISE description="Bootstrap machine: link + package layers + tools + login shell"
# 前提: リポジトリを clone 済み、`mise trust <repo>` 済み
#       (このタスク自体は `mise run bootstrap` で起動)。
set -euo pipefail

_SRC="${BASH_SOURCE[0]}"
while [ -L "$_SRC" ]; do
  _DIR="$(cd -P -- "$(dirname -- "$_SRC")" && pwd)"
  _SRC="$(readlink "$_SRC")"
  case "$_SRC" in /*) ;; *) _SRC="$_DIR/$_SRC" ;; esac
done
REPO="$(cd -P -- "$(dirname -- "$_SRC")/../../.." && pwd)"

# 先に symlink 配置 (冪等。二重実行可)。
"$REPO/config/mise/tasks/link.sh"

OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "== installing Homebrew =="
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  echo "== brew bundle =="
  brew bundle --file="$REPO/Brewfile" || {
    echo "HINT: tap trust で失敗したら \`brew tap <tap>\` を手動実行して再試行" >&2
    exit 1
  }
  if ! command -v nix >/dev/null 2>&1; then
    echo "Nix が未導入 (nix-darwin 用): https://nixos.org/download から導入後、"
    echo "  sudo darwin-rebuild switch --flake \"$REPO\""
  fi
elif [ "$OS" = "Linux" ]; then
  if command -v nix >/dev/null 2>&1; then
    echo "== optional nix profile (shared) =="
    nix profile remove dotfiles-shared 2>/dev/null || true
    nix profile install "$REPO#shared"
  else
    echo "Nix is not installed; skipping the optional shared native-tool layer." >&2
    echo "Install Nix later, then run: nix profile install \"$REPO#shared\"" >&2
  fi
else
  echo "unsupported OS: $OS" >&2
  exit 1
fi

echo "== mise install =="
mise install

echo "== pez install =="
pez install
pez doctor

echo "== login shell =="
SHIM="$HOME/.local/share/mise/shims/fish"
if [ ! -x "$SHIM" ]; then
  echo "fish shim が無い ($SHIM)。\`mise install\` の成否を確認" >&2
  exit 1
fi
if ! grep -qxF "$SHIM" /etc/shells 2>/dev/null; then
  echo "$SHIM" | sudo tee -a /etc/shells >/dev/null
fi
if [ "${SHELL:-}" != "$SHIM" ]; then
  chsh -s "$SHIM"
fi
echo "bootstrap: done. re-login to use fish."
