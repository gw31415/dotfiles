# rsplug 設定 (mise の {{ config_root }} は user-global では $HOME を指すため
# fish 側で symlink 解決した $DOTFILES から求める)。
if set -q DOTFILES
    set -gx RSPLUG_CONFIG_FILES "$DOTFILES/config/nvim_rsplug/*.toml"
end
