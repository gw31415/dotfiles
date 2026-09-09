# mise の有効化。対話シェルはフル有効化、非対話は shims のみ。
if status is-interactive
    mise activate fish | source
else
    mise activate fish --shims | source
end

# リポジトリ配置 (mise の {{ config_root }} は user-global では $HOME を指すため
# symlink 解決で求める。~/.config/mise -> <repo>/config/mise を想定)。
if not set -q DOTFILES
    set -l mise_dir (realpath ~/.config/mise 2>/dev/null)
    if test -n "$mise_dir"
        set -gx DOTFILES (path dirname (path dirname $mise_dir))
    end
end

# GPG エージェントの SSH ソケット・GitHub トークン (mise 管理の gpg/gh 前提)。
if command -q gpgconf
    set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
end
if command -q gh
    set -x GITHUB_TOKEN (gh auth token)
end
