# セッション PATH (旧 home-manager sessionPath 相当)。
# fish をログインシェルにすると zsh の PATH を継承しないため、files/zshenv と揃える。
fish_add_path -g "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/.go/bin"

# pnpm のグローバル bin (pnpm 本体は mise 管理)。
if test (uname) = Darwin
    set -gx PNPM_HOME "$HOME/Library/pnpm"
    fish_add_path -g "$PNPM_HOME/bin"
end

# OrbStack の CLI 統合 (インストーラが置くファイルがあるときだけ)。
if test -f "$HOME/.orbstack/shell/init2.fish"
    source "$HOME/.orbstack/shell/init2.fish"
end
