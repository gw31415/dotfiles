# mise-first 実装の dot。旧 dot-cli と同じ入口・フラグ・副コマンドを保ち、
# Home Manager が担当していた user-level apply だけを mise に移す。
function dot --description 'Apply dotfiles and system configuration'
    set -l original_argc (count $argv)

    # 旧 CLI と同様に、最初の非フラグ引数は副コマンドとして扱う。
    if test $original_argc -gt 0; and not string match -q -- '-*' $argv[1]
        set -l subcommand $argv[1]
        set -e argv[1]
        switch $subcommand
            case sh gc
                echo "[INFO] Running subcommand: dot-$subcommand"
                dot-$subcommand $argv
                return $status
            case '*'
                set -l path_subcommand "dot-$subcommand"
                if command -q "$path_subcommand"
                    echo "[INFO] Running subcommand: $path_subcommand"
                    command "$path_subcommand" $argv
                    return $status
                end
                echo "[ERROR] Unknown subcommand: $subcommand" >&2
                echo '[ERROR] Did you mean? dot-gc' >&2
                return 1
        end
    end

    argparse u/update h/home d/darwin a/all -- $argv
    or begin
        echo '[ERROR] Invalid arguments. Use -u, -h, -d, or -a.' >&2
        return 1
    end

    if set -q XDG_CONFIG_HOME
        set -l config_home "$XDG_CONFIG_HOME"
    else
        set -l config_home "$HOME/.config"
    end
    set -l mise_dir (realpath "$config_home/mise" 2>/dev/null)
    set -l repo
    if set -q DOTFILES; and test -f "$DOTFILES/config.toml"; and test -f "$DOTFILES/flake.nix"
        set repo "$DOTFILES"
    else if test -n "$mise_dir"; and test -f "$mise_dir/config.toml"; and test -f "$mise_dir/flake.nix"
        set repo "$mise_dir"
    end
    if test -z "$repo"; or not test -f "$repo/flake.nix"
        echo '[ERROR] Not installed. Install mise, then run `mise bootstrap --adopt <repo>`.' >&2
        return 1
    end

    # 旧 -d は macOS 以外では警告して無視する。
    if set -q _flag_darwin; and test (uname) != Darwin
        echo '[WARN] nix-darwin is not supported on this system. Ignoring --darwin.' >&2
        set -e _flag_darwin
    end

    # 旧 -u は lockfile 更新だけを行い、-h/-a があるときだけ続けて apply する。
    if set -q _flag_update
        echo '[INFO] Updating flake.lock...'
        command nix flake update --flake "$repo" --commit-lock-file
        or begin
            echo '[ERROR] Failed to update flake.lock.' >&2
            return 1
        end
        echo "[SUCCESS] Updated $repo/flake.lock."
    end

    # 引数なし、-h、-a は旧 Home Manager switch と同じ user-level apply。
    if set -q _flag_home; or set -q _flag_all; or test $original_argc -eq 0
        if not command -q mise
            echo '[ERROR] mise is not installed. Install mise, then run `mise bootstrap --adopt <repo>`.' >&2
            return 1
        else
            echo '[INFO] Switching user configuration...'
            command mise bootstrap
            or begin
                echo '[ERROR] Failed to bootstrap user configuration.' >&2
                return 1
            end
        end
    end

    # 旧 -d/-a と同じく、macOS では nix-darwin を apply する。
    if test (uname) = Darwin
        if set -q _flag_darwin; or set -q _flag_all
            echo '[INFO] Switching darwin-rebuild...'
            command sudo -H nix run "$repo#nix-darwin" -- switch --flake "$repo"
            or begin
                echo '[ERROR] Failed to switch darwin-rebuild.' >&2
                return 1
            end
        end
    end

    echo '[SUCCESS] Success.'
end
