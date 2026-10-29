set -g fish_greeting
bind \ea __fishify_replace_buffer

# 配色。dotfiles.theme は端末の背景 (light / dark) に合わせて fish が切り替える。
# universal 変数に残った旧配色より優先させるため、毎回 global に選び直す。
if status is-interactive
    if test -f $__fish_config_dir/themes/dotfiles.theme
        fish_config theme choose dotfiles
    else
        # theme がまだ配置されていない環境でも fish_prompt が壊れないようにする。
        for c in red yellow green blue
            set -g fish_color_prompt_$c $c
        end
        set -g fish_color_prompt_orange yellow
        set -g fish_color_prompt_aqua cyan
        set -g fish_color_prompt_purple magenta
        set -g fish_color_prompt_muted normal
    end
end
