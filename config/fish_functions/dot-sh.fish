# mise-first implementation of the historical `dot sh [command...]` entrypoint.
function dot-sh --description 'Open the dotfiles managed development shell'
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
    if test -n "$DOT_DEVSHELL"
        echo '[WARN] You are already in the devShell. Cancelled.' >&2
        return 1
    end
    if not command -q mise
        echo '[ERROR] mise is not installed. Install mise, then run `mise bootstrap --adopt <repo>`.' >&2
        return 1
    end

    echo '[INFO] Entering the devShell...'
    if test (count $argv) -eq 0
        if test -n "$SHELL"
            set -l cmd "$SHELL"
        else
            set -l cmd /bin/bash
        end
    else
        set -l cmd $argv
    end

    pushd "$repo" >/dev/null
    env DOT_DEVSHELL=1 mise exec -- $cmd
    set -l exit_code $status
    popd >/dev/null
    echo '[INFO] Exiting the devShell...'
    return $exit_code
end
