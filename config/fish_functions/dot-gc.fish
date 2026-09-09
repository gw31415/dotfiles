# mise-first migration keeps the historical Nix garbage-collection entrypoint.
function dot-gc --description 'Collect Nix garbage'
    argparse aggressive -- $argv
    or begin
        echo '[ERROR] Invalid arguments. Use --aggressive for a thorough cleanup.' >&2
        return 1
    end

    echo '[INFO] Cleaning up...'
    if set -q _flag_aggressive
        command nix-collect-garbage -d
        or begin
            echo '[ERROR] Failed to clean up.' >&2
            return 1
        end
        echo '[SUCCESS] Cleaned up aggressively.'
    else
        command nix store gc -v
        or begin
            echo '[ERROR] Failed to clean up.' >&2
            return 1
        end
        echo '[SUCCESS] Cleaned up.'
    end
end
