# fzf / fd (mise 管理)。
set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --exclude .git --follow --color=always"
set -gx FZF_DEFAULT_OPTS "--ansi"
if command -q fzf
    fzf --fish | source
end
