# 旧 dot-cli からの移行用互換関数。Home Manager は呼ばず、mise と
# nix-darwin の各責務へだけ委譲する。新規利用では `mise run` を使うこと。
function dot --description 'Compatibility wrapper for the retired Nix dot-cli'
    if contains -- --help $argv
        printf '%s\n' \
            'Usage: dot [-u] [-h] [-d] [-a]' \
            '  (none), -h, --home  Relink dotfiles with mise' \
            '  -d, --darwin         Apply nix-darwin on macOS' \
            '  -a, --all            Relink, then apply nix-darwin on macOS' \
            '  -u, --update         Update flake.lock only' \
            'Use `mise run update` to update mise, pez, and Homebrew tools.'
        return 0
    end

    set -l original_argc (count $argv)
    argparse u/update h/home d/darwin a/all -- $argv
    or begin
        echo '[ERROR] Invalid arguments. Use -u, -h, -d, or -a.' >&2
        return 2
    end
    if test (count $argv) -gt 0
        echo "[ERROR] dot subcommands are retired; use mise run or Nix directly." >&2
        return 2
    end

    set -l repo
    if set -q DOTFILES; and test -f "$DOTFILES/config/mise/config.toml"
        set repo "$DOTFILES"
    else
        set -l mise_dir (realpath "$HOME/.config/mise" 2>/dev/null)
        if test -n "$mise_dir"; and test -f "$mise_dir/config.toml"
            set repo (path dirname (path dirname "$mise_dir"))
        end
    end
    if test -z "$repo"
        echo '[ERROR] Cannot locate the dotfiles repository via DOTFILES or ~/.config/mise.' >&2
        echo 'Run ./config/mise/tasks/link.sh from the cloned repository first.' >&2
        return 1
    end

    if set -q _flag_update
        echo '[INFO] Updating flake.lock...'
        command nix flake update --flake "$repo"
        or return $status
    end

    if set -q _flag_home; or set -q _flag_all; or test $original_argc -eq 0
        if not command -q mise
            echo '[ERROR] mise is not installed yet.' >&2
            echo "Run $repo/config/mise/tasks/bootstrap.sh directly first." >&2
            return 1
        end
        echo '[INFO] Linking dotfiles with mise...'
        command mise run link
        or return $status
    end

    if test (uname) = Darwin
        if set -q _flag_darwin; or set -q _flag_all
            echo '[INFO] Switching nix-darwin...'
            command sudo -H nix run "$repo#nix-darwin" -- switch --flake "$repo"
            or return $status
        end
    else if set -q _flag_darwin
        echo '[WARN] nix-darwin is not supported on this system. Ignoring --darwin.' >&2
    end

    echo '[SUCCESS] Success.'
end
